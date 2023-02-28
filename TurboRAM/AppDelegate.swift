//
//  AppDelegate.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 10/2/23.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		MainWindowManager.shared.showWindow()
	}
}
