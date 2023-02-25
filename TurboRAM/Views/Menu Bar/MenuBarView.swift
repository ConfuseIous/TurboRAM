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
					Text(String(Int(process.memoryUsage)) + " MB")
				}
			}
			Divider()
			Button(action: {
				memoryInfoViewModel.reloadMemoryInfo()
			}, label: {
				HStack {
					Text("Reload")
						.foregroundColor(Color(nsColor: .labelColor))
						.underline()
					Spacer()
				}
			})
			.keyboardShortcut("r")
			.buttonStyle(.borderless)
			Button(action: {
				MainWindowManager.shared.showWindow()
			}, label: {
				HStack {
					Text("Show Main Window")
						.foregroundColor(Color(nsColor: .labelColor))
						.underline()
					Spacer()
				}
			})
			.keyboardShortcut("s")
			.buttonStyle(.borderless)
			Button(action: {
				
			}, label: {
				HStack {
					Text("Quit")
						.foregroundColor(Color(nsColor: .labelColor))
						.underline()
					Spacer()
				}
			})
			.keyboardShortcut("q")
			.buttonStyle(.borderless)
		}
		.padding()
		.onAppear() {
			memoryInfoViewModel.reloadMemoryInfo()
			memoryInfoViewModel.processes = memoryInfoViewModel.processes.filter({$0.memoryUsage >= 100})
		}
	}
}
