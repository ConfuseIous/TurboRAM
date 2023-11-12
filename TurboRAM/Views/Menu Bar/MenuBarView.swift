//
//  MenuBarView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 29/1/23.
//
//

import SwiftUI
import UserNotifications

struct MenuBarView: View {
	
	@ObservedObject var memoryInfoViewModel = MemoryInfoViewModel()
	
	@AppStorage("checkingFrequency") private var checkingFrequency = UserDefaults.standard.double(forKey: "checkingFrequency")
	@State private var timer = Timer.publish(every: UserDefaults.standard.double(forKey: "checkingFrequency"), on: .main, in: .common).autoconnect()
	
	func sendNotificationForOffendingProcesses(processes: [ProcessDetails]) {
		// This function exists only in the Menu Bar to prevent duplicate notifications being sent
		if !processes.isEmpty {
			var totalMemory: Float = 0.0
			for process in processes {
				totalMemory += process.memoryUsage
			}
			
			let content = UNMutableNotificationContent()
			content.title = "You can free \(totalMemory)MB of RAM"
			content.subtitle = (processes.count == 1) ? "1 process is hogging your computer's memory" : "\(processes.count) processes are hogging your computer's memory"
			content.sound = UNNotificationSound.default
			
			let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
			let request = UNNotificationRequest(identifier: "MemoryWarning", content: content, trigger: trigger)
			
			UNUserNotificationCenter.current().add(request)
		}
	}
	
	var body: some View {
		VStack {
			HStack {
				Text("TurboRAM")
					.font(.system(size: 20))
				Spacer()
			}.padding([.top, .horizontal])
			Divider()
				.padding(.horizontal)
			List(memoryInfoViewModel.processes) { process in
				HStack {
					Text(process.processName)
					Spacer()
					Text(String(Int(process.memoryUsage)) + " MB")
				}
			}
			Divider()
				.padding(.horizontal)
			VStack(spacing: 5) {
				Button(action: {
					memoryInfoViewModel.reloadMemoryInfo()
				}, label: {
					HStack {
						Text("Reload")
							.foregroundColor(Color(nsColor: .labelColor))
						Spacer()
						HStack(spacing: 4) {
							Image(systemName: "command")
								.foregroundColor(.secondary)
							Text("R")
								.foregroundColor(.secondary)
						}
					}
				})
				.keyboardShortcut("r")
				.buttonStyle(.plain)
				.foregroundColor(Color(nsColor: .windowBackgroundColor))
				Button(action: {
					MainWindowManager.shared.showWindow()
				}, label: {
					HStack {
						Text("Show Main Window")
							.foregroundColor(Color(nsColor: .labelColor))
						Spacer()
						HStack(spacing: 4) {
							Image(systemName: "command")
								.foregroundColor(.secondary)
							Text("S")
								.foregroundColor(.secondary)
						}
					}
				})
				.keyboardShortcut("s")
				.buttonStyle(.plain)
				.foregroundColor(Color(nsColor: .windowBackgroundColor))
				Button(action: {
					NSApp.terminate(self)
				}, label: {
					HStack {
						Text("Quit")
							.foregroundColor(Color(nsColor: .labelColor))
						Spacer()
						HStack(spacing: 4) {
							Image(systemName: "command")
								.foregroundColor(.secondary)
							Text("Q")
								.foregroundColor(.secondary)
						}
					}
				})
				.keyboardShortcut("q")
				.buttonStyle(.plain)
				.foregroundColor(Color(nsColor: .windowBackgroundColor))
			}
			.padding(.horizontal, 15)
			.padding(.bottom, 10)
		}
		.onAppear() {
			memoryInfoViewModel.reloadMemoryInfo()
			// Not sure if this is useful
			// sendNotificationForOffendingProcesses(processes: memoryInfoViewModel.findOffendingProcesses())
		}
		.onReceive(timer) { _ in
			memoryInfoViewModel.reloadMemoryInfo()
		}
		.onChange(of: checkingFrequency, perform: { _ in
			self.timer = Timer.publish(every: UserDefaults.standard.double(forKey: "checkingFrequency"), on: .main, in: .common).autoconnect()
		})
		.frame(height: 500)
	}
}
