//
//  TurboRAMApp.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 12/11/22.
//

import SwiftUI

@main
struct TurboRAMApp: App {
	
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	
	init() {
		if UserDefaults.standard.double(forKey: "minimumMemoryUsageThreshold") == 0.0 {
			UserDefaults.standard.set(500.0, forKey: "minimumMemoryUsageThreshold")
		}
		if UserDefaults.standard.double(forKey: "minimumMemoryUsageminimumMultiplier") == 0.0 {
			UserDefaults.standard.set(1.5, forKey: "minimumMemoryUsageminimumMultiplier")
		}
	}
	
	var body: some Scene {
		MenuBarExtra("TurboRAM", systemImage: "cpu") {
			MenuBarView()
		}.menuBarExtraStyle(.window)
	}
}
