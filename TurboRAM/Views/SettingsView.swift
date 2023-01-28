//
//  SettingsView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 2/12/22.
//

import SwiftUI

struct SettingsView: View {
	
	@State private var shouldShowConfirmationAlert: Bool = false
	@Binding var shouldShowSettingsSheet: Bool
	
	@State private var threshold: String = String(UserDefaults.standard.double(forKey: "minimumMemoryUsageThreshold"))
	@State private var minimumMultiplier: String = String(UserDefaults.standard.double(forKey: "minimumMemoryUsageminimumMultiplier"))
	
	var body: some View {
		VStack {
			HStack {
				Text("Settings")
					.font(.system(size: 30))
				Spacer()
				Button(action: {
					shouldShowSettingsSheet.toggle()
				}, label: {
					Text("Cancel")
				}).padding(.leading)
			}.padding(.bottom)
			Divider()
			Text("TurboRAM will alert you if any of process uses \(minimumMultiplier) times more memory from when it was first tracked and is now using \(threshold)MB of memory or more.")
				.font(.system(size: 12))
				.foregroundColor(.secondary)
			VStack {
				HStack {
					Text("Ignore processes that use less than:")
					Spacer()
				}
				HStack {
					TextField("", text: $threshold)
					Text("(in MB)")
				}
				HStack {
					Text("of memory.")
					Spacer()
				}
			}.padding(.vertical)
			VStack {
				HStack {
					Text("Warn me if a process uses:")
					Spacer()
				}
				TextField("", text: $minimumMultiplier)
				HStack {
					Text("times more memory than when it was first tracked.")
					Spacer()
				}
			}.padding(.vertical)
			Spacer()
			Button(action: {
				let acceptableThresholdRange = 200.0...1000.0
				guard let thresholdDouble = Double(threshold), acceptableThresholdRange.contains(thresholdDouble) else {
					shouldShowConfirmationAlert.toggle()
					return
				}
				
				let acceptableMultiplierRange = 1.2...2
				guard let minimumMultiplierDouble = Double(minimumMultiplier), acceptableMultiplierRange.contains(minimumMultiplierDouble) else {
					shouldShowConfirmationAlert.toggle()
					return
				}
				
				UserDefaults.standard.set(thresholdDouble, forKey: "minimumMemoryUsageThreshold")
				UserDefaults.standard.set(minimumMultiplierDouble, forKey: "minimumMemoryUsageminimumMultiplier")
				
				shouldShowSettingsSheet.toggle()
			}, label: {
				Image(systemName: "checkmark.circle.fill")
					.font(.system(size: 40))
			}).buttonStyle(.borderless)
			Spacer()
		}
		.alert(isPresented: $shouldShowConfirmationAlert) {
			Alert(
				title: Text("These values appear to be irregular. Are you sure you want to save them?"),
				primaryButton: .destructive(Text("Yes")) {
					if let thresholdDouble = Double(threshold) {
						UserDefaults.standard.set(thresholdDouble, forKey: "minimumMemoryUsageThreshold")
					}
					if let minimumMultiplierDouble = Double(minimumMultiplier) {
						UserDefaults.standard.set(minimumMultiplierDouble, forKey: "minimumMemoryUsageminimumMultiplier")
					}
					
					shouldShowSettingsSheet.toggle()
				},
				secondaryButton: .cancel())
		}
		.frame(width: 400, height: 400)
		.padding()
	}
}
