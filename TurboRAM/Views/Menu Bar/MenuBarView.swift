//
//  MenuBarView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 29/1/23.
//
//

import SwiftUI

struct MenuBarView: View {
	
	@ObservedObject var memoryInfoViewModel = MemoryInfoViewModel()
	
	@AppStorage("checkingFrequency") private var checkingFrequency = UserDefaults.standard.double(forKey: "checkingFrequency")
	@State private var timer = Timer.publish(every: UserDefaults.standard.double(forKey: "checkingFrequency"), on: .main, in: .common).autoconnect()
	
	var body: some View {
		VStack {
			HStack {
				Text("TurboRAM")
					.font(.system(size: 20))
				Spacer()
			}.padding([.top, .horizontal])
			Divider()
			List(memoryInfoViewModel.processes) { process in
				HStack {
					Text(process.processName)
					Spacer()
					Text(String(Int(process.memoryUsage)) + " MB")
				}
			}
			Divider()
			VStack {
				Button(action: {
					memoryInfoViewModel.reloadMemoryInfo()
				}, label: {
					HStack {
						Text("Reload")
							.foregroundColor(Color(nsColor: .labelColor))
						Spacer()
					}
				})
				.keyboardShortcut("r")
				Button(action: {
					MainWindowManager.shared.showWindow()
				}, label: {
					HStack {
						Text("Show Main Window")
							.foregroundColor(Color(nsColor: .labelColor))
						Spacer()
					}
				})
				.keyboardShortcut("s")
				Button(action: {
					NSApp.terminate(self)
				}, label: {
					HStack {
						Text("Quit")
							.foregroundColor(Color(nsColor: .labelColor))
						Spacer()
					}
				})
				.keyboardShortcut("q")
			}.padding([.bottom, .horizontal], 10)
		}
		.onAppear() {
			memoryInfoViewModel.reloadMemoryInfo()
			memoryInfoViewModel.processes = memoryInfoViewModel.processes.filter({$0.memoryUsage >= 100})
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
