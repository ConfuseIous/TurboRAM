//
//  FinishSetupView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 5/2/23.
//

import SwiftUI

struct FinishSetupView: View {
	
	@State private var shouldShowError = false
	@Binding var shouldShowSetupSheet: Bool
	
	let memoryInfoViewModel: MemoryInfoViewModel
	
	var body: some View {
		VStack(spacing: 20) {
			Text("Great! The scripts have been saved.")
				.font(.system(size: 15))
				.multilineTextAlignment(.center)
				.padding()
			Text("Next, they need permission to run.")
				.font(.system(size: 15))
				.multilineTextAlignment(.center)
				.padding()
			Text("Before proceeding, you may first read the scripts and understand that they are safe to run.")
				.font(.system(size: 15))
				.multilineTextAlignment(.center)
				.padding()
			Text("To grant permission, open a new Terminal window and run these commands:")
				.font(.system(size: 15))
				.multilineTextAlignment(.center)
				.padding()
			Text("chmod u+x ~/Library/Application\\ Scripts/com.karandeepsingh.TurboRAM/GetProcessInfo.sh && chmod u+x ~/Library/Application\\ Scripts/com.karandeepsingh.TurboRAM/KillProcess.sh && && chmod u+x ~/Library/Application\\ Scripts/com.karandeepsingh.TurboRAM/GetMemoryPressure.sh")
				.padding()
				.font(.system(size: 10))
				.background(.black)
				.foregroundColor(.white)
			Button(action: {
				let pasteboard = NSPasteboard.general
				pasteboard.clearContents()
				pasteboard.writeObjects(["chmod u+x ~/Library/Application\\ Scripts/com.karandeepsingh.TurboRAM/GetProcessInfo.sh && chmod u+x ~/Library/Application\\ Scripts/com.karandeepsingh.TurboRAM/KillProcess.sh && chmod u+x ~/Library/Application\\ Scripts/com.karandeepsingh.TurboRAM/GetMemoryPressure.sh" as NSString])
			}, label: {
				Text("Copy Command")
			})
			Spacer()
			Button(action: {
				MemoryInfoViewModel.verifyScriptFiles(completion: { success in
					if success {
						memoryInfoViewModel.reloadMemoryInfo()
						UserDefaults.standard.set(true, forKey: "setupCompleted")
						shouldShowSetupSheet.toggle()
					} else {
						shouldShowError.toggle()
					}
				})
			}, label: {
				VStack {
					Image(systemName: "checkmark.circle")
						.font(.system(size: 30))
						.padding(5)
					Text("Confirm")
				}
			}).buttonStyle(.borderless)
			Spacer()
		}
		.padding()
		.alert(isPresented: $shouldShowError, content: {
			Alert(
				title: Text("Something went wrong"),
				message: Text("Please give the scripts permission to be executed.")
			)
		})
	}
}
