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
		VStack {
			Text("Great! The script has been saved.")
				.font(.system(size: 15))
				.multilineTextAlignment(.center)
				.padding()
			Text("Next, it needs permission to run.")
				.font(.system(size: 15))
				.multilineTextAlignment(.center)
				.padding()
			Text("Before proceeding, you are highly encouraged to first read the script and understand that it is safe to run.")
				.font(.system(size: 15))
				.multilineTextAlignment(.center)
				.padding()
			Text("To grant permission, open a new Terminal window and run this command:")
				.font(.system(size: 15))
				.multilineTextAlignment(.center)
				.padding()
			Text("chmod u+x ~/Library/Application\\ Scripts/com.karandeepsingh.TurboRAM/GetProcessInfo.sh && chmod u+x ~/Library/Application\\ Scripts/com.karandeepsingh.TurboRAM/KillProcess.sh")
				.padding()
				.font(.system(size: 10))
				.background(.black)
				.foregroundColor(.white)
			Button(action: {
				let pasteboard = NSPasteboard.general
				pasteboard.clearContents()
				pasteboard.writeObjects(["chmod u+x ~/Library/Application\\ Scripts/com.karandeepsingh.TurboRAM/GetProcessInfo.sh && chmod u+x ~/Library/Application\\ Scripts/com.karandeepsingh.TurboRAM/KillProcess.sh" as NSString])
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
				message: Text("Please give the script permission to be executed.")
			)
		})
	}
}
