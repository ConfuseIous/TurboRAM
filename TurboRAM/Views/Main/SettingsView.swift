//
//  SettingsView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 2/12/22.
//

import SwiftUI

struct SettingsView: View {

    @Binding var shouldShowSettingsSheet: Bool

    @State private var threshold:         String = String(format: "%.0f", UserDefaults.standard.float(forKey: "minimumMemoryUsageThreshold"))
    @State private var minimumMultiplier: String = String(format: "%.2g", UserDefaults.standard.float(forKey: "minimumMemoryUsageMultiplier"))
    @State private var checkingFrequency: String = String(format: "%.0f", UserDefaults.standard.float(forKey: "checkingFrequency"))

    @State private var showOutOfRangeAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // ── Toolbar ──────────────────────────────────────────────────
            HStack {
                Text("Settings")
                    .font(.headline)
                Spacer()
                Button("Cancel") { shouldShowSettingsSheet = false }
                    .buttonStyle(.borderless)
            }
            .padding(16)
            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // ── Thresholds ────────────────────────────────────────
                    GroupBox {
                        VStack(alignment: .leading, spacing: 14) {
                            settingRow(
                                icon: "memorychip",
                                title: "Minimum memory threshold",
                                detail: "Ignore processes using less than this amount",
                                field: $threshold,
                                unit: "MB",
                                placeholder: "500"
                            )
                            Divider()
                            settingRow(
                                icon: "arrow.up.right.circle",
                                title: "Growth multiplier",
                                detail: "Warn when a process grows by at least this factor",
                                field: $minimumMultiplier,
                                unit: "×",
                                placeholder: "1.5"
                            )
                            Divider()
                            settingRow(
                                icon: "clock.arrow.2.circlepath",
                                title: "Check frequency",
                                detail: "How often TurboRAM scans processes",
                                field: $checkingFrequency,
                                unit: "seconds",
                                placeholder: "60"
                            )
                        }
                        .padding(4)
                    } label: {
                        Label("Detection Rules", systemImage: "slider.horizontal.3")
                    }

                    // ── Info ──────────────────────────────────────────────
                    InfoAccordion()

                    // ── Ignored list ──────────────────────────────────────
                    IgnoredProcessesAccordion()

                    // ── Contact ───────────────────────────────────────────
                    ContactAccordion()
                }
                .padding(16)
            }

            Divider()
            // ── Save ─────────────────────────────────────────────────────
            HStack {
                Spacer()
                Button {
                    save()
                } label: {
                    Label("Save Settings", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(16)
        }
        .frame(width: 420, height: 660)
        .alert("Values out of recommended range", isPresented: $showOutOfRangeAlert) {
            Button("Save Anyway", role: .destructive) { forceSave() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Threshold: 200–1000 MB · Multiplier: 1.2–2.0× · Frequency: 60–600s")
        }
    }

    // MARK: - Row helper

    @ViewBuilder
    private func settingRow(icon: String, title: String, detail: String, field: Binding<String>, unit: String, placeholder: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
				.foregroundStyle(Color.accentColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.medium)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    TextField(placeholder, text: field)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                    Text(unit)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Save logic

    private func isInRange() -> Bool {
        guard let t = Float(threshold),  (200...1000).contains(t) else { return false }
        guard let m = Float(minimumMultiplier), (1.2...2.0).contains(m) else { return false }
        guard let f = Float(checkingFrequency),  (60...600).contains(f) else { return false }
        return true
    }

    private func save() {
        if isInRange() {
            forceSave()
        } else {
            showOutOfRangeAlert = true
        }
    }

    private func forceSave() {
        if let t = Float(threshold)         { UserDefaults.standard.set(t, forKey: "minimumMemoryUsageThreshold") }
        if let m = Float(minimumMultiplier) { UserDefaults.standard.set(m, forKey: "minimumMemoryUsageMultiplier") }
        if let f = Float(checkingFrequency) { UserDefaults.standard.set(f, forKey: "checkingFrequency") }
        shouldShowSettingsSheet = false
    }
}

// MARK: - Info accordion

private struct InfoAccordion: View {
    @State private var expanded = false
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3)) { expanded.toggle() }
                } label: {
                    HStack {
                        Text("Why does TurboRAM show different values than Activity Monitor?")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .rotationEffect(expanded ? .degrees(90) : .zero)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                if expanded {
                    Text("TurboRAM reports the **resident size** — actual physical RAM used by a process. Activity Monitor shows the **virtual memory size**, which also includes swap space reserved on disk. TurboRAM's numbers will always be lower and more reflective of real RAM pressure.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Divider()
                    Text("TurboRAM only alerts when **both** thresholds are met AND system memory pressure is ≥ 75%. Under good conditions it stays silent.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(4)
        } label: {
            Label("FAQ", systemImage: "questionmark.circle")
        }
    }
}

// MARK: - Ignored processes accordion

private struct IgnoredProcessesAccordion: View {
    @State private var expanded = false
    @State private var ignoredNames: [String] = UserDefaults.standard.array(forKey: "ignoredProcessNames") as? [String] ?? []

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3)) { expanded.toggle() }
                } label: {
                    HStack {
                        Text("Ignored Processes")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        if !ignoredNames.isEmpty {
                            Text("\(ignoredNames.count)")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15), in: Capsule())
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .rotationEffect(expanded ? .degrees(90) : .zero)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                if expanded {
                    if ignoredNames.isEmpty {
                        Label("No processes ignored", systemImage: "eye.slash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(ignoredNames, id: \.self) { name in
                            HStack {
                                Image(systemName: "eye.slash")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(name)
                                    .font(.subheadline)
                                Spacer()
                                Button("Remove") {
                                    ignoredNames.removeAll { $0 == name }
                                    UserDefaults.standard.set(ignoredNames, forKey: "ignoredProcessNames")
                                }
                                .buttonStyle(.borderless)
                                .foregroundStyle(.red)
                                .font(.caption)
                            }
                        }
                    }
                }
            }
            .padding(4)
        } label: {
            Label("Ignored Processes", systemImage: "eye.slash")
        }
    }
}

// MARK: - Contact accordion

private struct ContactAccordion: View {
    @Environment(\.openURL) var openURL
    @State private var expanded = false

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3)) { expanded.toggle() }
                } label: {
                    HStack {
                        Text("Contact the Developer")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .rotationEffect(expanded ? .degrees(90) : .zero)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)

                if expanded {
                    HStack(spacing: 10) {
                        Button {
                            openURL(URL(string: "mailto:apps.karandeepsingh@icloud.com")!)
                        } label: {
                            Label("Email", systemImage: "envelope")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)

                        Button {
                            openURL(URL(string: "https://twitter.com/confuseious")!)
                        } label: {
                            Label("Twitter / X", systemImage: "bird")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(4)
        } label: {
            Label("Support", systemImage: "envelope")
        }
    }
}
