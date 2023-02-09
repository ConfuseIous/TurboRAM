//
//  TurboRAMApp.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 12/11/22.
//

import SwiftUI

@main
struct TurboRAMApp: App {
	
	init() {
		if UserDefaults.standard.double(forKey: "minimumMemoryUsageThreshold") == 0.0 {
			UserDefaults.standard.set(500.0, forKey: "minimumMemoryUsageThreshold")
		}
		if UserDefaults.standard.double(forKey: "minimumMemoryUsageminimumMultiplier") == 0.0 {
			UserDefaults.standard.set(1.5, forKey: "minimumMemoryUsageminimumMultiplier")
		}
	}
	
	var body: some Scene {
		//		if #available(macOS 13.0, *) {
		WindowGroup {
			HomeView()
				.environmentObject(MemoryInfoViewModel())
				.onAppear {
					let window = NSApp.windows.first
					window?.level = .floating
				}
		}
		.windowResizability(.contentSize)
		MenuBarExtra(content: {
			MenuBarView()
				.environmentObject(MemoryInfoViewModel())
		}, label: {
			Image(systemName: "cpu")
		}).menuBarExtraStyle(.window)
	}
}
