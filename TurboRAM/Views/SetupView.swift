//
//  SetupView.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 5/2/23.
//

import SwiftUI

struct SetupView: View {
	
	@State private var shouldExpand = false
	@Binding var shouldShowSetupSheet: Bool
	
	func openFolderSelectionPanel(completion: @escaping (URL?) -> Void) {
		let openPanel = NSOpenPanel()
		
		let launcherLogPathWithTilde = "~/Library/Application Scripts/com.karandeepsingh.TurboRAM" as NSString
		let expandedLauncherLogPath = launcherLogPathWithTilde.expandingTildeInPath
		openPanel.directoryURL = NSURL.fileURL(withPath: expandedLauncherLogPath, isDirectory: true)
		openPanel.canChooseDirectories = true
		openPanel.canChooseFiles = false
		openPanel.allowsMultipleSelection = false
		openPanel.begin { (result) -> Void in
			completion(openPanel.url)
		}
	}
	
	var body: some View {
		VStack {
			Text("Welcome to TurboRAM.")
				.font(.system(size: 25))
				.padding()
			Text("To get process information, TurboRAM uses a simple script.")
				.font(.system(size: 15))
				.padding()
			Text("To proceed, please allow TurboRAM to save this script by clicking on the Allow button and then on Open.")
				.font(.system(size: 15))
				.padding()
			ZStack {
				RoundedRectangle(cornerRadius: 10)
					.foregroundColor(Color(nsColor: .windowBackgroundColor))
				VStack {
					Button(action: {
						withAnimation {
							shouldExpand.toggle()
						}
					}, label: {
						HStack {
							Text("If you are an advanced user and want to verify the contents of this script:")
								.font(.system(size: 15))
								.foregroundColor(.secondary)
								.padding()
							Image(systemName: "chevron.right")
								.rotationEffect(shouldExpand ? Angle(degrees: 90) : Angle(degrees: 0))
						}
					}).buttonStyle(.borderless)
					Divider()
					if shouldExpand {
						Text("This script just runs the top command, which returns a sorted list of system processes. It will be stored in")
						Text("~/Library/Application Scripts/com.karandeepsingh.TurboRAM")
							.font(.system(size: 10))
							.padding()
							.background(.black)
							.foregroundColor(.white)
							.padding(.bottom, 20)
						Text("The exact command is:")
						Text("top -o mem -l 1 -stats \"command,mem,pid\"")
							.font(.system(size: 10))
							.padding()
							.background(.black)
							.foregroundColor(.white)
					}
				}.padding()
			}
			.frame(height: shouldExpand ? 400 : 120)
			.padding(.vertical)
			Spacer()
			Button(action: {
				openFolderSelectionPanel(completion: { folderURL in
					DispatchQueue.global(qos: .userInitiated).async {
						do {
							if let folderURL {
								let fileURL = folderURL.appendingPathComponent("script.sh").path
								let file = URL(fileURLWithPath: Bundle.main.path(forResource: "script", ofType: "sh")!)
								let data = try Data(contentsOf: file)
								try data.write(to: URL(fileURLWithPath: fileURL))
								print("yeet!")
							} else {
								print("not yeet")
							}
						} catch {
							print("very unyeet")
						}
					}
				})
			}, label: {
				Text("Allow")
			})
			Spacer()
		}
		.frame(width: 400, height: 750)
		.padding()
	}
}
