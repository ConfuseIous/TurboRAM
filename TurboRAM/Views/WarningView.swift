//
//  WarningView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 26/1/23.
//

import SwiftUI

struct WarningView: View {
	
	let processes: [ProcessDetails]
	
	var body: some View {
		VStack {
			HStack {
				Text("These processes have seen a significant increase in memory usage of over 20% from the time they were first tracked.")
				Spacer()
				Button(action: {
					
				}, label: {
					Text("Done")
				}).padding(.leading)
			}
			Divider()
			Spacer()
			ForEach(processes) { process in
				ZStack {
					RoundedRectangle(cornerRadius: 20)
					HStack {
						Text(process.processName)
						Spacer()
					}
					HStack {
						Text("Current Usage: \(process.memoryUsage)MB")
						Spacer()
					}
					Button(action: {
						
					}, label: {
						Text("Quit Process")
					})
					Button(action: {
						
					}, label: {
						Text("Ignore Process Today")
					})
					Button(action: {
						
					}, label: {
						Text("Ignore Process Forever")
					})
				}
			}
			Spacer()
		}
		.frame(width: 400, height: 400)
		.padding()
	}
}
