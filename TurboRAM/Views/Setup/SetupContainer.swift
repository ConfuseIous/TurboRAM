//
//  SetupContainer.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 5/2/23.
//

import SwiftUI

struct SetupContainer: View {
	
	@State private var scriptInstalled = false
	@Binding var shouldShowSetupSheet: Bool
	
	let memoryInfoViewModel: MemoryInfoViewModel
	
	var body: some View {
		VStack {
			if !scriptInstalled {
				SetupView(scriptInstalled: $scriptInstalled)
			} else {
				FinishSetupView(shouldShowSetupSheet: $shouldShowSetupSheet, memoryInfoViewModel: memoryInfoViewModel)
			}
		}.frame(width: 400, height: 750)
	}
}
