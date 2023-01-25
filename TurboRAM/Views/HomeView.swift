//
//  HomeView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 12/11/22.
//

import SwiftUI

struct HomeView: View {
	
	@State private var rotationAngle: Angle = Angle(degrees: 0)
	
	@State private var shouldShowSettingsSheet = false
	@State private var shouldShowInfoSheet = false
	
	@State private var selectedIndex: Int?
	
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
							withAnimation {
								
							}
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
					}
					HStack {
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
						.padding()
						Button(action: {
							withAnimation {
								shouldShowInfoSheet.toggle()
							}
						}) {
							Image(systemName: "info.circle")
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 20)
						}
						.buttonStyle(PlainButtonStyle())
						.padding()
					}
				}
			}.contentShape(Rectangle()) // Makes the entire area tappable
			Table(memoryInfoViewModel.processes, selection: $selectedIndex) {
				TableColumn("Name", value: \.processName)
				TableColumn("Memory Used (Megabytes)") { Text(String($0.memoryUsage)) }
				TableColumn("Process ID") { Text(String($0.id)) }
			}
		}
		.onAppear() {
			memoryInfoViewModel.reloadMemoryInfo()
		}
		.onTapGesture {
			selectedIndex = nil
		}
		.frame(width: 800, height: 800)
		.sheet(isPresented: $shouldShowSettingsSheet, content: {
			SettingsView()
		})
		.sheet(isPresented: $shouldShowInfoSheet, content: {
			InfoView()
		})
		.padding()
		.fixedSize(horizontal: true, vertical: false)
	}
}
