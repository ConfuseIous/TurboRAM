//
//  MenuBarView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 29/1/23.
//
//

import SwiftUI

struct MenuBarView: View {
	
	let memoryInfoViewModel = MemoryInfoViewModel()
	
	var body: some View {
		VStack {
			HStack {
				Text("TurboRAM")
					.font(.system(size: 20))
				Spacer()
			}
			List(memoryInfoViewModel.processes) { process in
				HStack {
					Text(process.processName)
					Spacer()
					Text(String(process.memoryUsage))
				}
			}
			Divider()
			Button("Reload") {
				memoryInfoViewModel.reloadMemoryInfo()
			}
			.keyboardShortcut("r")
			.buttonStyle(.borderless)
			Button("Show Main Window") {
				MainWindowManager.shared.showWindow()
			}
			.keyboardShortcut("s")
			.buttonStyle(.borderless)
			Button("Quit") {
				NSApplication.shared.terminate(nil)
			}
			.keyboardShortcut("q")
			.buttonStyle(.borderless)
		}
		.padding()
		.onAppear() {
			print("onappear")
			memoryInfoViewModel.reloadMemoryInfo()
			memoryInfoViewModel.processes = memoryInfoViewModel.processes.filter({$0.memoryUsage >= 100})
			print(memoryInfoViewModel.processes.count)
		}
	}
}
