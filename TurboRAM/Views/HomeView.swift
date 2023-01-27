//
//  HomeView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 12/11/22.
//

import SwiftUI

struct HomeView: View {
	
	let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect() // Check every minute
	
	@State private var selectedIndex: Int?
	
	@State private var rotationAngle: Angle = Angle(degrees: 0)
	
	@State private var shouldShowSettingsSheet = false
	@State private var shouldShowWarningSheet = false
	
	@State private var offendingProcesses: [ProcessDetails] = []
	
	@State private var shouldShowQuitConfirmationAlert = false
	
	@EnvironmentObject var memoryInfoViewModel: MemoryInfoViewModel
	
	var body: some View {
		VStack {
			HStack {
				Text("TurboRAM")
					.font(.title)
				Spacer()
				VStack {
					HStack {
						Button(action: {
							withAnimation {
								rotationAngle += Angle(degrees: 360)
								memoryInfoViewModel.reloadMemoryInfo()
							}
						}) {
							Image(systemName: "arrow.clockwise.circle")
								.resizable()
								.aspectRatio(contentMode: .fit)
								.rotationEffect(rotationAngle)
								.frame(width: 20)
						}
						.buttonStyle(PlainButtonStyle())
						.padding(.horizontal)
						Button(action: {
							shouldShowQuitConfirmationAlert.toggle()
						}) {
							Image(systemName: "x.circle")
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 20)
								.foregroundColor(selectedIndex == nil ? .primary : .red)
						}
						.disabled(selectedIndex == nil)
						.buttonStyle(PlainButtonStyle())
						.padding(.horizontal)
						Button(action: {
							withAnimation {
								shouldShowSettingsSheet.toggle()
							}
						}) {
							Image(systemName: "gear.circle")
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 20)
						}
						.buttonStyle(PlainButtonStyle())
						.padding(.horizontal)
					}
				}
			}.contentShape(Rectangle()) // Makes the entire area tappable
			Table(memoryInfoViewModel.processes, selection: $selectedIndex) {
				TableColumn("Name", value: \.processName)
				TableColumn("Memory Used (Megabytes)") { Text(String($0.memoryUsage)) }
				TableColumn("Process ID") { Text(String($0.id)) }
			}
		}
		.alert(isPresented: $shouldShowQuitConfirmationAlert) {
			if let selectedIndex {
				return Alert(
					title: Text("Quit this process?"),
					primaryButton: .destructive(Text("Quit")) {
						memoryInfoViewModel.quitProcessWithPID(pid: selectedIndex)
						withAnimation {
							memoryInfoViewModel.processes.remove(at: memoryInfoViewModel.processes.firstIndex(where: {$0.id == selectedIndex})!)
							self.selectedIndex = nil
						}
					},
					secondaryButton: .cancel()
				)
			} else {
				return Alert(
					title: Text("Something went wrong"),
					message: Text("Couldn't find the selected process. Please refresh and try again.")
				)
			}
		}
		.onAppear() {
			memoryInfoViewModel.reloadMemoryInfo()
			//			offendingProcesses = memoryInfoViewModel.processes
			//			shouldShowWarningSheet.toggle()
		}
		.onReceive(timer) { _ in
			print("DEBUG: timer RECEIVED")
			memoryInfoViewModel.reloadMemoryInfo()
			offendingProcesses = memoryInfoViewModel.findOffendingProcesses()
			if !offendingProcesses.isEmpty {
				shouldShowWarningSheet.toggle()
				print("DEBUG: TOGGLED shouldShowWarningSheet")
			}
		}
		.onTapGesture {
			selectedIndex = nil
		}
		.frame(width: 800, height: 800)
		.sheet(isPresented: $shouldShowSettingsSheet, content: {
			SettingsView(shouldShowSettingsSheet: $shouldShowSettingsSheet)
		})
		.sheet(isPresented: $shouldShowWarningSheet, content: {
			WarningView(processes: offendingProcesses, shouldShowWarningSheet: $shouldShowWarningSheet)
		})
		.padding()
		.fixedSize(horizontal: true, vertical: false)
	}
}
