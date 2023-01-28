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
	
	@State private var threshold: String = String(UserDefaults.standard.float(forKey: "minimumMemoryUsageThreshold"))
	@State private var minimumMultiplier: String = String(UserDefaults.standard.float(forKey: "minimumMemoryUsageminimumMultiplier"))
	
	var body: some View {
		VStack(spacing: 20) {
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
			}
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
			}.padding(.bottom)
			InfoView()
			ContactView()
			Spacer()
			Button(action: {
				let acceptableThresholdRange = 200.0...1000.0
				guard let thresholdFloat = Float(threshold), acceptableThresholdRange.contains(Double(thresholdFloat)) else {
					shouldShowConfirmationAlert.toggle()
					return
				}
				
				let acceptableMultiplierRange = 1.2...2
				guard let minimumMultiplierFloat = Float(minimumMultiplier), acceptableMultiplierRange.contains(Double(minimumMultiplierFloat)) else {
					shouldShowConfirmationAlert.toggle()
					return
				}
				
				UserDefaults.standard.set(thresholdFloat, forKey: "minimumMemoryUsageThreshold")
				UserDefaults.standard.set(minimumMultiplierFloat, forKey: "minimumMemoryUsageminimumMultiplier")
				
				shouldShowSettingsSheet.toggle()
			}, label: {
				Image(systemName: "checkmark.circle.fill")
					.font(.system(size: 40))
			})
			.buttonStyle(.borderless)
			.padding()
		}
		.alert(isPresented: $shouldShowConfirmationAlert) {
			Alert(
				title: Text("These values appear to be irregular. Are you sure you want to save them?"),
				primaryButton: .destructive(Text("Yes")) {
					if let thresholdFloat = Float(threshold) {
						UserDefaults.standard.set(thresholdFloat, forKey: "minimumMemoryUsageThreshold")
					}
					if let minimumMultiplierFloat = Float(minimumMultiplier) {
						UserDefaults.standard.set(minimumMultiplierFloat, forKey: "minimumMemoryUsageminimumMultiplier")
					}
					
					shouldShowSettingsSheet.toggle()
				},
				secondaryButton: .cancel())
		}
		.frame(width: 400, height: 750)
		.padding()
	}
	
	struct InfoView: View {
		
		@State private var shouldExpand = false
		
		var body: some View {
			ZStack {
				RoundedRectangle(cornerRadius: 10)
					.foregroundColor(Color(nsColor: .windowBackgroundColor))
				VStack {
					Button(action: {
						withAnimation {
							shouldExpand.toggle()
						}
					}, label: {
						HStack {
							Text("INFO")
								.fontWeight(.bold)
							Spacer()
							Image(systemName: "chevron.right")
								.rotationEffect(shouldExpand ? Angle(degrees: 90) : Angle(degrees: 0))
						}
					}).buttonStyle(.borderless)
					Divider()
					if shouldExpand {
						HStack {
							Text("Why are TurboRAM's values different from those in activity monitor?")
								.font(.system(size: 13))
							Spacer()
						}
						HStack {
							Text("Activity Monitor uses the virtual memory size of a process, which includes both the physical memory (RAM) used by the process and any additional space reserved for the process in the swap file. TurboRAM shows the resident size of a process, which is the amount of physical memory (RAM) being used by the process only.")
								.font(.system(size: 12))
							Spacer()
						}.padding(.top, 5)
					}
				}.padding()
			}.frame(height: shouldExpand ? nil : 50)
		}
	}
	
	struct ContactView: View {
		
		@Environment(\.openURL) var openURL
		
		@State private var shouldExpand = false
		
		var body: some View {
			ZStack {
				RoundedRectangle(cornerRadius: 10)
					.foregroundColor(Color(nsColor: .windowBackgroundColor))
				VStack {
					Button(action: {
						withAnimation {
							shouldExpand.toggle()
						}
					}, label: {
						HStack {
							Text("CONTACT ME")
								.fontWeight(.bold)
							Spacer()
							Image(systemName: "chevron.right")
								.rotationEffect(shouldExpand ? Angle(degrees: 90) : Angle(degrees: 0))
						}
					}).buttonStyle(.borderless)
					Divider()
					if shouldExpand {
						HStack {
							Button(action: {
								openURL(URL(string: "mailto:apps.karandeepsingh@icloud.com")!)
							}) {
								HStack {
									Spacer()
									Text("Email")
										.padding(3)
									Spacer()
								}
							}
							.buttonStyle(BorderlessButtonStyle())
							.foregroundColor(.white)
							.background(Color(NSColor.brown))
							.cornerRadius(5)
							Button(action: {
								openURL(URL(string: "https://twitter.com/confuseious")!)
							}) {
								HStack {
									Spacer()
									Text("Twitter")
										.padding(3)
									Spacer()
								}
							}
							.buttonStyle(BorderlessButtonStyle())
							.foregroundColor(.white)
							.background(Color(NSColor(red: 74/255, green: 153/255, blue: 233/255, alpha: 1)))
							.cornerRadius(5)
						}
					}
				}.padding()
			}.frame(height: shouldExpand ? 100 : 50)
		}
	}
}
