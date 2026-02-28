//
//  TurboRAMApp.swift
//  TurboRAM
//

import SwiftUI

@main
struct TurboRAMApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Set default values if never configured
        let defaults: [String: Any] = [
            "minimumMemoryUsageThreshold":    500.0,
            "minimumMemoryUsageMultiplier":   1.5,
            "checkingFrequency":              60.0
        ]
        defaults.forEach { key, value in
            if UserDefaults.standard.object(forKey: key) == nil {
                UserDefaults.standard.set(value, forKey: key)
            }
        }
    }

    var body: some Scene {
        MenuBarExtra("TurboRAM", systemImage: "memorychip") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}
