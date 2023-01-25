//
//  TurboRAMApp.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 12/11/22.
//

import SwiftUI

@main
struct TurboRAMApp: App {
	var body: some Scene {
		WindowGroup {
			HomeView()
		}.windowResizability(.contentSize)
	}
}
