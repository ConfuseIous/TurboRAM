//
//  HomeView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 12/11/22.
//

import SwiftUI
import UserNotifications

struct HomeView: View {

    @AppStorage("checkingFrequency") private var checkingFrequency = UserDefaults.standard.double(forKey: "checkingFrequency")
    @AppStorage("minimumMemoryUsageMultiplier") private var minimumMemoryUsageMultiplier = UserDefaults.standard.double(forKey: "minimumMemoryUsageMultiplier")
    @AppStorage("minimumMemoryUsageThreshold") private var minimumMemoryUsageThreshold = UserDefaults.standard.double(forKey: "minimumMemoryUsageThreshold")

    @State private var timer = Timer.publish(every: UserDefaults.standard.double(forKey: "checkingFrequency"), on: .main, in: .common).autoconnect()
    @State private var selectedProcessID: Int?
    @State private var rotationAngle: Angle = .zero
    @State private var shouldShowSettingsSheet = false
    @State private var shouldShowWarningSheet = false
    @State private var shouldShowQuitConfirmationAlert = false
    @State private var offendingProcesses: [ProcessDetails] = []

    @ObservedObject var memoryInfoViewModel = MemoryInfoViewModel()

    private let memFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()

    // MARK: - Pressure colour

    private var pressureColor: Color {
        switch memoryInfoViewModel.memoryPressurePercent {
        case 0..<50:  return Color(red: 0.20, green: 0.78, blue: 0.35) // green
        case 50..<75: return Color(red: 1.00, green: 0.62, blue: 0.04) // amber
        default:      return Color(red: 0.95, green: 0.23, blue: 0.21) // red
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            pressureBar
            Divider()
            processTable
            Divider()
            footerBar
        }
        .frame(width: 780, height: 760)
        .background(Color(nsColor: .windowBackgroundColor))
        // ── Alerts ──────────────────────────────────────────────────────────
        .alert("Quit this process?", isPresented: $shouldShowQuitConfirmationAlert) {
            Button("Quit", role: .destructive) {
                if let pid = selectedProcessID {
                    memoryInfoViewModel.quitProcessWithPID(pid: pid)
                    withAnimation {
                        memoryInfoViewModel.processes.removeAll { $0.id == pid }
                        selectedProcessID = nil
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let pid = selectedProcessID,
               let proc = memoryInfoViewModel.processes.first(where: { $0.id == pid }) {
                Text("\(proc.processName) (PID \(pid)) will be force-quit immediately.")
            }
        }
        // ── Sheets ──────────────────────────────────────────────────────────
        .sheet(isPresented: $shouldShowSettingsSheet) {
            SettingsView(shouldShowSettingsSheet: $shouldShowSettingsSheet)
        }
        .sheet(isPresented: $shouldShowWarningSheet) {
            WarningView(
                shouldShowWarningSheet: $shouldShowWarningSheet,
                offendingProcesses: $offendingProcesses,
                memoryInfoViewModel: memoryInfoViewModel
            )
        }
        // ── Lifecycle ────────────────────────────────────────────────────────
        .onAppear {
            memoryInfoViewModel.reloadMemoryInfo()
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        }
        .onReceive(timer) { _ in
            memoryInfoViewModel.reloadMemoryInfo()
            let offenders = memoryInfoViewModel.findOffendingProcesses()
            if !offenders.isEmpty {
                offendingProcesses = offenders
                shouldShowWarningSheet = true
            }
        }
        .onChange(of: checkingFrequency) { _ in
            timer = Timer.publish(every: UserDefaults.standard.double(forKey: "checkingFrequency"), on: .main, in: .common).autoconnect()
        }
    }

    // MARK: - Subviews

    private var headerBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "memorychip")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("TurboRAM")
                    .font(.headline)
                Text("Monitors processes for memory growth")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Reload
            Button {
                withAnimation(.easeInOut(duration: 0.5)) { rotationAngle += .degrees(360) }
                memoryInfoViewModel.reloadMemoryInfo()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .rotationEffect(rotationAngle)
            }
//            .buttonStyle(.accessoryBar)
            .help("Refresh process list")
            .keyboardShortcut("r", modifiers: .command)

            // Quit selected
            Button {
                shouldShowQuitConfirmationAlert = true
            } label: {
                Image(systemName: "xmark.circle")
            }
//            .buttonStyle(.accessoryBar)
            .disabled(selectedProcessID == nil)
            .help("Force-quit selected process")

            // Settings
            Button {
                shouldShowSettingsSheet = true
            } label: {
                Image(systemName: "gear")
            }
//            .buttonStyle(.accessoryBar)
            .help("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var pressureBar: some View {
        HStack(spacing: 10) {
            Label {
                Text("Memory Pressure")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "gauge.with.dots.needle.33percent")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Pill percentage
            Text("\(memoryInfoViewModel.memoryPressurePercent)%")
                .font(.subheadline.monospacedDigit())
                .fontWeight(.semibold)
                .foregroundStyle(pressureColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(pressureColor.opacity(0.12), in: Capsule())
            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(height: 6)
                    Capsule()
                        .fill(pressureColor)
                        .frame(width: geo.size.width * CGFloat(memoryInfoViewModel.memoryPressurePercent) / 100.0, height: 6)
                        .animation(.easeInOut(duration: 0.4), value: memoryInfoViewModel.memoryPressurePercent)
                }
                .frame(height: geo.size.height)
            }
            .frame(width: 140, height: 14)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    @ViewBuilder
    private var processTable: some View {
        if memoryInfoViewModel.isLoading {
            VStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.85)
                Text("Scanning processes…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Table(memoryInfoViewModel.processes, selection: $selectedProcessID) {
                TableColumn("Process Name") { proc in
                    Text(proc.processName)
                        .lineLimit(1)
                        .help(proc.processName)
                }
                .width(min: 200, ideal: 300)

                TableColumn("Memory (MB)") { proc in
                    HStack {
                        Text(memFormatter.string(from: proc.memoryUsage as NSNumber) ?? "–")
                            .monospacedDigit()
                            .foregroundStyle(memoryColor(for: proc.memoryUsage))
                        Spacer()
                    }
                }
                .width(min: 100, ideal: 130)

                TableColumn("Baseline (MB)") { proc in
                    if let base = memoryInfoViewModel.initialValues[proc.id] {
                        let ratio = proc.memoryUsage / base
                        HStack {
                            Text(memFormatter.string(from: base as NSNumber) ?? "–")
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            if ratio >= 1.5 {
                                Image(systemName: "arrow.up.right")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
                        }
                    } else {
                        Text("–").foregroundStyle(.secondary)
                    }
                }
                .width(min: 110, ideal: 140)

                TableColumn("PID") { proc in
                    Text("\(proc.id)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .width(min: 60, ideal: 80)
            }
        }
    }

    private var footerBar: some View {
        HStack {
            if let pid = selectedProcessID,
               let proc = memoryInfoViewModel.processes.first(where: { $0.id == pid }) {
                Label("\(proc.processName)  ·  PID \(proc.id)  ·  \(memFormatter.string(from: proc.memoryUsage as NSNumber) ?? "")MB", systemImage: "cpu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("\(memoryInfoViewModel.processes.count) processes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Auto-refreshes every \(Int(checkingFrequency))s")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func memoryColor(for mb: Float) -> Color {
        switch mb {
        case 0..<500:   return .primary
        case 500..<1500: return Color(red: 1.00, green: 0.62, blue: 0.04)
        default:         return Color(red: 0.95, green: 0.23, blue: 0.21)
        }
    }
}
