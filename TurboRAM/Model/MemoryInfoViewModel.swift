//
//  MemoryInfoViewModel.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 14/11/22.
//

import AppKit
import Foundation
import UserNotifications
import Darwin

class MemoryInfoViewModel: ObservableObject {

    /// Baseline memory readings captured the first time each PID is seen.
    var initialValues: [Int: Float] = [:]

    @Published var isLoading: Bool = false
    @Published var processes: [ProcessDetails] = []
    @Published var memoryPressurePercent: Int = 0

    init() {
        self.reloadMemoryInfo()
    }

    // MARK: - Reload

    func reloadMemoryInfo() {
        isLoading = true

        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self else { return }

            let fetched  = Self.fetchProcessList()
            let pressure = Self.fetchMemoryPressurePercent()

            // Preserve baselines; only record a first-seen entry for new PIDs.
            var baseline = self.initialValues
            for p in fetched where baseline[p.id] == nil {
                baseline[p.id] = p.memoryUsage
            }

            DispatchQueue.main.async {
                self.initialValues         = baseline
                self.processes             = fetched
                self.memoryPressurePercent = pressure
                self.isLoading             = false
            }
        }
    }

    // MARK: - Process list  (replaces GetProcessInfo.sh)

    /// Enumerates all system processes using sysctl(KERN_PROC_ALL) combined with
    /// proc_pidinfo(PROC_PIDTASKINFO) for memory.
    ///
    /// How it works:
    ///   1. sysctl(KERN_PROC_ALL) returns a list of kinfo_proc structs, which gives
    ///      us every PID and its 16-char process name. This call requires no special
    ///      privilege in a non-sandboxed app.
    ///   2. proc_pidinfo(PROC_PIDTASKINFO) retrieves precise byte-level resident size
    ///      for each PID. It succeeds for processes owned by the current user and
    ///      returns -1 / a short count for processes owned by root or other users.
    ///      Those processes are included in the list with memoryUsage = 0.
    static func fetchProcessList() -> [ProcessDetails] {
        // ──────────────────────────────────────────────────────────────────────
        // Step 1: Determine required buffer size from the kernel
        // ──────────────────────────────────────────────────────────────────────
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var neededBytes  = 0

        guard sysctl(&mib, 4, nil, &neededBytes, nil, 0) == 0,
              neededBytes > 0
        else { return [] }

        // ──────────────────────────────────────────────────────────────────────
        // Step 2: Allocate a raw byte buffer (avoids Swift's struct init issues
        // when handing memory to a C API via void*)
        // ──────────────────────────────────────────────────────────────────────
        let entryStride = MemoryLayout<kinfo_proc>.stride
        let capacity    = (neededBytes / entryStride) + 32

        let rawBuffer = UnsafeMutableRawPointer.allocate(
            byteCount: capacity * entryStride,
            alignment: MemoryLayout<kinfo_proc>.alignment
        )
        defer { rawBuffer.deallocate() }

        // Zero-fill so unused tail entries are clean
        rawBuffer.initializeMemory(as: UInt8.self, repeating: 0, count: capacity * entryStride)

        // ──────────────────────────────────────────────────────────────────────
        // Step 3: Fetch process list
        // ──────────────────────────────────────────────────────────────────────
        var actualBytes = capacity * entryStride
        guard sysctl(&mib, 4, rawBuffer, &actualBytes, nil, 0) == 0,
              actualBytes > 0
        else { return [] }

        let procCount = actualBytes / entryStride
        guard procCount > 0 else { return [] }

        // ──────────────────────────────────────────────────────────────────────
        // Step 4: Walk entries
        // ──────────────────────────────────────────────────────────────────────
        let typedBuffer = rawBuffer.bindMemory(to: kinfo_proc.self, capacity: procCount)

        // proc_pidinfo return value and argument are both Int32; capture the
        // expected size once so the per-loop comparison is same-type.
        let expectedTaskInfoSize = Int32(MemoryLayout<proc_taskinfo>.size)

        var result = [ProcessDetails]()
        result.reserveCapacity(procCount)

        for i in 0..<procCount {
            let entry = typedBuffer[i]

            // pid_t is Int32
            let pid = entry.kp_proc.p_pid
            guard pid > 0 else { continue }

            // p_comm is a (Int8, Int8, … × MAXCOMLEN+1) tuple in Swift.
            // Reading it safely via withUnsafeBytes:
            var comm = entry.kp_proc.p_comm
            let name: String = withUnsafeBytes(of: &comm) { bytes in
                guard let baseAddr = bytes.baseAddress else { return "" }
                return String(cString: baseAddr.assumingMemoryBound(to: CChar.self))
            }
            guard !name.isEmpty else { continue }

            // ── Memory via proc_pidinfo ───────────────────────────────────────
            // ret is Int32; expectedTaskInfoSize is Int32 → type-safe comparison
            var taskInfo = proc_taskinfo()
            let ret: Int32 = proc_pidinfo(pid, PROC_PIDTASKINFO, 0,
                                          &taskInfo, expectedTaskInfoSize)
            let residentMB: Float
            if ret == expectedTaskInfoSize {
                residentMB = Float(taskInfo.pti_resident_size) / 1_048_576.0
            } else {
                // Process is owned by another user (root / system daemon): list
                // it but we cannot read its memory.  Show 0 so it is still
                // visible; the user can see it in the table.
                residentMB = 0.0
            }

            result.append(ProcessDetails(id: Int(pid),
                                         processName: name,
                                         memoryUsage: residentMB))
        }

        // Sort: non-zero memory (our processes) descend to top,
        // zero-memory (system procs we can't read) fall to the bottom.
        return result.sorted { $0.memoryUsage > $1.memoryUsage }
    }

    // MARK: - Memory pressure  (replaces GetMemoryPressure.sh)

    /// Reads system-wide VM statistics via the Mach kernel host port.
    /// Returns an integer in 0–100 representing memory pressure.
    static func fetchMemoryPressurePercent() -> Int {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size
        )

        let kr: kern_return_t = withUnsafeMutablePointer(to: &stats) { statsPtr in
            statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, ptr, &count)
            }
        }

        guard kr == KERN_SUCCESS else { return 0 }

        let page     = UInt64(vm_kernel_page_size)
        let used     = (UInt64(stats.active_count) + UInt64(stats.wire_count)) * page
        let total    = used
                     + UInt64(stats.inactive_count) * page
                     + UInt64(stats.free_count)     * page
        guard total > 0 else { return 0 }

        return min(100, Int(Double(used) / Double(total) * 100.0))
    }

    // MARK: - Offending processes

    func findOffendingProcesses() -> [ProcessDetails] {
        guard memoryPressurePercent >= 75 else { return [] }

        let ignoredNames = getPermanentlyIgnoredProcessNames()
        let thresholdMB  = UserDefaults.standard.float(forKey: "minimumMemoryUsageThreshold")
        let multiplier   = UserDefaults.standard.float(forKey: "minimumMemoryUsageMultiplier")

        return processes.filter { process in
            guard !ignoredNames.contains(process.processName) else { return false }
            guard process.memoryUsage >= thresholdMB          else { return false }
            guard process.memoryUsage > 0                     else { return false }
            guard let baseline = initialValues[process.id]    else { return false }
            return process.memoryUsage >= baseline * multiplier
        }
    }

    // MARK: - Quit process  (replaces KillProcess.sh)

    func quitProcessWithPID(pid: Int) {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = kill(pid_t(pid), SIGKILL)
        }
    }

    // MARK: - Helpers

    private func getPermanentlyIgnoredProcessNames() -> [String] {
        UserDefaults.standard.array(forKey: "ignoredProcessNames") as? [String] ?? []
    }
}
