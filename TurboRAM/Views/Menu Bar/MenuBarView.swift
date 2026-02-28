//
//  MenuBarView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 29/1/23.
//

import SwiftUI
import UserNotifications

struct MenuBarView: View {

    @ObservedObject var memoryInfoViewModel = MemoryInfoViewModel()

    @AppStorage("checkingFrequency") private var checkingFrequency = UserDefaults.standard.double(forKey: "checkingFrequency")
    @State private var timer = Timer.publish(every: max(UserDefaults.standard.double(forKey: "checkingFrequency"), 30), on: .main, in: .common).autoconnect()

    private let fmt: NumberFormatter = {
        let f = NumberFormatter()
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 1
        return f
    }()

    private var pressureColor: Color {
        switch memoryInfoViewModel.memoryPressurePercent {
        case 0..<50:  return Color(red: 0.20, green: 0.78, blue: 0.35)
        case 50..<75: return Color(red: 1.00, green: 0.62, blue: 0.04)
        default:      return Color(red: 0.95, green: 0.23, blue: 0.21)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ─────────────────────────────────────────────────────
            HStack {
                Image(systemName: "memorychip")
                    .foregroundStyle(.secondary)
                Text("TurboRAM")
                    .font(.headline)
                Spacer()
                if memoryInfoViewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 16, height: 16)
                } else {
                    Button {
                        memoryInfoViewModel.reloadMemoryInfo()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // ── Pressure bar ───────────────────────────────────────────────
            HStack(spacing: 8) {
                Text("Pressure")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(nsColor: .separatorColor)).frame(height: 5)
                        Capsule()
                            .fill(pressureColor)
                            .frame(width: geo.size.width * CGFloat(memoryInfoViewModel.memoryPressurePercent) / 100.0, height: 5)
                            .animation(.easeInOut, value: memoryInfoViewModel.memoryPressurePercent)
                    }
                    .frame(height: geo.size.height)
                }
                .frame(height: 12)
                Text("\(memoryInfoViewModel.memoryPressurePercent)%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(pressureColor)
                    .frame(width: 34, alignment: .trailing)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            Divider()

            // ── Process list ───────────────────────────────────────────────
            List(memoryInfoViewModel.processes.prefix(20)) { process in
                HStack {
                    Text(process.processName)
                        .lineLimit(1)
                        .font(.subheadline)
                    Spacer()
                    Text((fmt.string(from: process.memoryUsage as NSNumber) ?? "–") + " MB")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .listStyle(.plain)
            .frame(maxHeight: .infinity)

            Divider()

            // ── Footer buttons ─────────────────────────────────────────────
            VStack(spacing: 1) {
                menuButton("Show Main Window", icon: "macwindow", shortcut: "s") {
                    MainWindowManager.shared.showWindow()
                }
                menuButton("Quit TurboRAM", icon: "power", shortcut: "q") {
                    NSApp.terminate(nil)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
        }
        .frame(height: 500)
        .onAppear { memoryInfoViewModel.reloadMemoryInfo() }
        .onReceive(timer) { _ in
            memoryInfoViewModel.reloadMemoryInfo()
            let offenders = memoryInfoViewModel.findOffendingProcesses()
            sendNotification(for: offenders)
        }
        .onChange(of: checkingFrequency) { _ in
            timer = Timer.publish(every: max(UserDefaults.standard.double(forKey: "checkingFrequency"), 30), on: .main, in: .common).autoconnect()
        }
    }

    // MARK: - Notification

    private func sendNotification(for processes: [ProcessDetails]) {
        guard !processes.isEmpty else { return }
        let total = processes.reduce(0.0) { $0 + $1.memoryUsage }
        let content = UNMutableNotificationContent()
        content.title = "Memory Alert — \(fmt.string(from: total as NSNumber) ?? "")MB can be freed"
        content.subtitle = processes.count == 1
            ? "\(processes[0].processName) is using excessive memory"
            : "\(processes.count) processes are hogging memory"
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: "MemoryWarning-\(Date().timeIntervalSince1970)", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        )
    }

    // MARK: - Menu button

    @ViewBuilder
    private func menuButton(_ label: String, icon: String, shortcut: Character, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Label(label, systemImage: icon)
                    .foregroundStyle(Color(nsColor: .labelColor))
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "command")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(shortcut).uppercased())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
        }
        .keyboardShortcut(KeyEquivalent(shortcut), modifiers: .command)
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.clear)
        )
    }
}
