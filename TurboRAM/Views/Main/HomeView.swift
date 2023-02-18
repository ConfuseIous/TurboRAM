//
//  HomeView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 12/11/22.
//

import SwiftUI
import UserNotifications

struct HomeView: View {
	
	@AppStorage("checkingFrequency") private var checkingFrequency = UserDefaults.standard.double(forKey: "checkingFrequency")
	@AppStorage("minimumMemoryUsageMultiplier") private var minimumMemoryUsageMultiplier = UserDefaults.standard.double(forKey: "minimumMemoryUsageMultiplier")
	@AppStorage("minimumMemoryUsageThreshold") private var minimumMemoryUsageThreshold = UserDefaults.standard.double(forKey: "minimumMemoryUsageThreshold")
	
	@State private var timer = Timer.publish(every: UserDefaults.standard.double(forKey: "checkingFrequency"), on: .main, in: .common).autoconnect()
	
	@State private var selectedIndex: Int?
	
	@State private var rotationAngle: Angle = Angle(degrees: 0)
	
	@State private var shouldShowSetupSheet = false
	@State private var shouldShowSettingsSheet = false
	@State private var shouldShowWarningSheet = false
	
	@State private var shouldShowQuitConfirmationAlert = false
	
	@ObservedObject var memoryInfoViewModel = MemoryInfoViewModel()
	
	let formatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.minimumFractionDigits = 0
		formatter.maximumFractionDigits = 2
		
		return formatter
	}()
	
	var body: some View {
		VStack {
			HStack {
				VStack {
					HStack {
						Text("TurboRAM")
							.font(.title)
						Spacer()
					}
					HStack {
						Text("TurboRAM will alert you if any process uses \(formatter.string(from: minimumMemoryUsageMultiplier as NSNumber) ?? "unknown") times the memory it was using when it was first tracked and is now using \(formatter.string(from: minimumMemoryUsageThreshold as NSNumber) ?? "")MB of memory or more.")
							.font(.system(size: 12))
							.foregroundColor(.secondary)
						Spacer()
					}.padding(.top, 5)
				}
				Spacer()
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
			}.contentShape(Rectangle()) // Makes the entire area tappable
			if memoryInfoViewModel.isLoading {
				Spacer()
				ProgressView()
					.progressViewStyle(.circular)
				Text("Loading")
				Spacer()
			} else {
				Table(memoryInfoViewModel.processes, selection: $selectedIndex) {
					TableColumn("Name", value: \.processName)
					TableColumn("Memory Used (Megabytes)") { Text(String($0.memoryUsage)) }
					TableColumn("Process ID") { Text(String($0.id)) }
				}
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
			
			UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
				if success {
					print("Notification permission granted")
				} else if let error = error {
					print(error.localizedDescription)
				}
			}
			
			if !UserDefaults.standard.bool(forKey: "setupCompleted") {
				UserDefaults.standard.set(500, forKey: "minimumMemoryUsageThreshold")
				UserDefaults.standard.set(1.5, forKey: "minimumMemoryUsageMultiplier")
				UserDefaults.standard.set(60, forKey: "checkingFrequency")
				shouldShowSetupSheet.toggle()
			}
		}
		.onReceive(timer) { _ in
			debugPrint("DEBUG: timer RECEIVED")
			memoryInfoViewModel.reloadMemoryInfo()
			if !memoryInfoViewModel.offendingProcesses.isEmpty {
				shouldShowWarningSheet.toggle()
				debugPrint("DEBUG: TOGGLED shouldShowWarningSheet")
			}
		}
		.onChange(of: checkingFrequency, perform: { _ in
			self.timer = Timer.publish(every: UserDefaults.standard.double(forKey: "checkingFrequency"), on: .main, in: .common).autoconnect()
		})
		.onTapGesture {
			selectedIndex = nil
		}
		.frame(width: 750, height: 750)
		.sheet(isPresented: $shouldShowSetupSheet, content: {
			SetupContainer(shouldShowSetupSheet: $shouldShowSetupSheet, memoryInfoViewModel: memoryInfoViewModel)
				.interactiveDismissDisabled()
		})
		.sheet(isPresented: $shouldShowSettingsSheet, content: {
			SettingsView(shouldShowSettingsSheet: $shouldShowSettingsSheet)
		})
		.sheet(isPresented: $shouldShowWarningSheet, content: {
			WarningView(shouldShowWarningSheet: $shouldShowWarningSheet, memoryInfoViewModel: memoryInfoViewModel)
		})
		.padding()
		.fixedSize(horizontal: true, vertical: false)
	}
}
