//
//  SettingsView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 2/12/22.
//

import SwiftUI

struct SettingsView: View {
	
	@Binding var shouldShowSettingsSheet: Bool
	
	var body: some View {
		VStack {
			HStack {
				Text("Settings")
				Spacer()
				Button(action: {
					shouldShowSettingsSheet.toggle()
				}, label: {
					Text("Done")
				}).padding(.leading)
			}.padding(.bottom)
			Divider()
			Text("TurboRAM will alert you if any of your processes see an increase in memory usage of over 50% from the time they were first tracked and are now using 500MB of memory or more")
		}
		.frame(width: 400, height: 400)
		.padding()
	}
}
