//
//  WarningView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 26/1/23.
//

import SwiftUI

struct WarningView: View {
	
	let processes: [ProcessDetails]
	
	@Binding var shouldShowWarningSheet: Bool
	
	var body: some View {
		VStack {
			HStack {
				Text("These processes have seen a significant increase in memory usage of over 20% from the time they were first tracked and are now using 500MB of memory or more.")
				Spacer()
				Button(action: {
					shouldShowWarningSheet.toggle()
				}, label: {
					Text("Done")
				}).padding(.leading)
			}.padding(.bottom)
			Divider()
			List(processes) { process in
				ZStack {
					RoundedRectangle(cornerRadius: 10)
						.foregroundColor(Color(nsColor: .windowBackgroundColor))
					VStack {
						HStack {
							Text(process.processName)
							Spacer()
							Text("Current Usage: \(Int(process.memoryUsage))MB")
						}
						Button(action: {
//							quitProcessWithPID(process.id)
						}, label: {
							HStack {
								Spacer()
								Text("Quit Process")
								Spacer()
							}
						})
						Button(action: {
							
						}, label: {
							Spacer()
							Text("Ignore Process Today")
							Spacer()
						})
						Button(action: {
							
						}, label: {
							Spacer()
							Text("Ignore Process Forever")
							Spacer()
						})
					}.padding()
				}
			}
			Spacer()
		}
		.onAppear() {
			print(processes.count)
		}
		.frame(width: 400, height: 400)
		.padding()
	}
}
