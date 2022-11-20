//
//  ContentView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 12/11/22.
//

import SwiftUI

struct ContentView: View {
	var body: some View {
		VStack {
			Image(systemName: "globe")
				.imageScale(.large)
				.foregroundColor(.accentColor)
		}
		.padding()
		.onAppear(perform: {
			_ = MemoryInfo.getMemoryInfo()
		})
	}
}
