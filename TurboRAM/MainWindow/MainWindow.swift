//
//  MainWindow.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 10/2/23.
//

import SwiftUI
import Foundation

class MainWindow<HomeView: View>: NSWindowController {
	
	convenience init(rootView: HomeView) {
		let hostingCtrl = NSHostingController(rootView: rootView.frame(width: 800, height: 800))
		let window = NSWindow(contentViewController: hostingCtrl)
		window.setContentSize(NSSize(width: 800, height: 800))
		self.init(window: window)
	}
}
