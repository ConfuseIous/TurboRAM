//
//  MainWindowManager.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 10/2/23.
//

import Foundation

class MainWindowManager {

	static let shared = MainWindowManager()
	
	let mainWindow = MainWindow(rootView: HomeView())
	
	func showWindow() {
		mainWindow.window?.titleVisibility = .hidden
		mainWindow.window?.makeKeyAndOrderFront(nil)
		mainWindow.window?.orderFrontRegardless()
		mainWindow.window?.windowController?.showWindow(self)
	}
}
