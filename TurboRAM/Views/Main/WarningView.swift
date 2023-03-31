//
//  WarningView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 26/1/23.
//

import SwiftUI

struct WarningView: View {
	
	@AppStorage("minimumMemoryUsageminimumMultiplier") private var minimumMemoryUsageminimumMultiplier = UserDefaults.standard.double(forKey: "minimumMemoryUsageminimumMultiplier")
	@AppStorage("minimumMemoryUsageThreshold") private var minimumMemoryUsageThreshold = UserDefaults.standard.double(forKey: "minimumMemoryUsageThreshold")
	
	@Binding var shouldShowWarningSheet: Bool
	
	@Binding var  offendingProcesses: [ProcessDetails]
	
	let memoryInfoViewModel: MemoryInfoViewModel
	
	let formatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.minimumFractionDigits = 0
		formatter.maximumFractionDigits = 2
		
		return formatter
	}()
	
	var body: some View {
		VStack {
			HStack {
				Text("These processes have increased their memory usage to \(formatter.string(from: minimumMemoryUsageminimumMultiplier as NSNumber) ?? "unknown") times the memory when they were first tracked and are now using \(formatter.string(from: minimumMemoryUsageThreshold as NSNumber) ?? "")MB of memory or more.")
				Spacer()
				Button(action: {
					shouldShowWarningSheet.toggle()
				}, label: {
					Text("Done")
				}).padding(.leading)
			}.padding(.bottom)
			Divider()
			if offendingProcesses.isEmpty {
				Spacer()
				Text("No Processes")
					.font(.system(size: 25))
					.foregroundColor(.secondary)
			} else {
				List(offendingProcesses) { process in
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
								if let index = offendingProcesses.firstIndex(where: {$0.id == process.id}) {
									memoryInfoViewModel.quitProcessWithPID(pid: process.id)
									offendingProcesses.remove(at: index)
									memoryInfoViewModel.reloadMemoryInfo()
								}
							}, label: {
								HStack {
									Spacer()
									Text("Quit Process")
									Spacer()
								}
							})
							//						Button(action: {
							//							memoryInfoViewModel.ignoredProcessIDs.append(process.id)
							//						}, label: {
							//							Spacer()
							//							Text("Ignore Process Today")
							//							Spacer()
							//						})
							Button(action: {
								if let index = offendingProcesses.firstIndex(where: {$0.id == process.id}) {
									// memoryInfoViewModel.ignoredProcessIDs.append(process.id)
									var ignoredProcessNames: [String] = (UserDefaults.standard.array(forKey: "ignoredProcessNames") as? [String] ?? [])
									ignoredProcessNames.append(process.processName)
									UserDefaults.standard.set(ignoredProcessNames, forKey: "ignoredProcessNames")
									
									withAnimation {
										offendingProcesses.remove(at: index)
										memoryInfoViewModel.reloadMemoryInfo()
									}
								}
							}, label: {
								Spacer()
								Text("Ignore Process Forever")
								Spacer()
							})
						}.padding()
					}
				}
			}
			Spacer()
		}
		.frame(width: 400, height: 400)
		.padding()
	}
}
