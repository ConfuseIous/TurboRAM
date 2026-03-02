//
//  WarningView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 26/1/23.
//

import SwiftUI

struct WarningView: View {

    @AppStorage("minimumMemoryUsageMultiplier") private var multiplier = UserDefaults.standard.double(forKey: "minimumMemoryUsageMultiplier")
    @AppStorage("minimumMemoryUsageThreshold")  private var threshold  = UserDefaults.standard.double(forKey: "minimumMemoryUsageThreshold")

    @Binding var shouldShowWarningSheet: Bool
    @Binding var offendingProcesses: [ProcessDetails]

    let memoryInfoViewModel: MemoryInfoViewModel

    private let fmt: NumberFormatter = {
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Memory Alert")
                        .font(.headline)
                    Text("These processes have grown ≥ \(fmt.string(from: multiplier as NSNumber) ?? "")× and are using ≥ \(fmt.string(from: threshold as NSNumber) ?? "")MB while memory pressure is high.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Done") { shouldShowWarningSheet = false }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            .padding(16)

            Divider()

            if offendingProcesses.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text("No offending processes")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(offendingProcesses) { process in
                        OffendingProcessRow(
                            process: process,
                            baseline: memoryInfoViewModel.initialValues[process.id],
                            fmt: fmt,
                            onQuit: {
                                memoryInfoViewModel.quitProcessWithPID(pid: process.id)
                                removeProcess(process)
                                memoryInfoViewModel.reloadMemoryInfo()
                            },
                            onIgnoreForever: {
                                var ignored = UserDefaults.standard.array(forKey: "ignoredProcessNames") as? [String] ?? []
                                if !ignored.contains(process.processName) {
                                    ignored.append(process.processName)
                                    UserDefaults.standard.set(ignored, forKey: "ignoredProcessNames")
                                }
                                removeProcess(process)
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 480, height: 480)
    }

    private func removeProcess(_ process: ProcessDetails) {
        withAnimation {
            offendingProcesses.removeAll { $0.id == process.id }
        }
    }
}

// MARK: - Row

private struct OffendingProcessRow: View {

    let process: ProcessDetails
    let baseline: Float?
    let fmt: NumberFormatter
    let onQuit: () -> Void
    let onIgnoreForever: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(process.processName)
                    .fontWeight(.medium)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Label("\(fmt.string(from: process.memoryUsage as NSNumber) ?? "")MB now", systemImage: "memorychip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let base = baseline {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Label("\(fmt.string(from: base as NSNumber) ?? "")MB baseline", systemImage: "chart.xyaxis.line")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            Button {
                onIgnoreForever()
            } label: {
                Label("Ignore", systemImage: "eye.slash")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .tint(.secondary)

            Button {
                onQuit()
            } label: {
                Label("Force Quit", systemImage: "xmark.circle")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(.red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}
