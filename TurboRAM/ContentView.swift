//
//  ContentView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 12/11/22.
//

import SwiftUI

struct ContentView: View {
	
	@State private var processDetails: [ProcessDetails] = MemoryInfo.getMemoryInfo()
	
	var body: some View {
		NavigationStack {
			VStack {
				List(processDetails) { detail in
					Text(detail.processName)
				}
			}.navigationTitle("TurboRAM")
		}
		.padding()
//		.onAppear(perform: {
//			for i in MemoryInfo.getMemoryInfo() {
//				print(i.processName, i.memoryUsage)
//			}
//		})
	}
}
