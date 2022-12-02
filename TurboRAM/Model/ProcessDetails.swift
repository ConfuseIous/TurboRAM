//
//  ProcessDetails.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 20/11/22.
//

import Foundation

struct ProcessDetails: Identifiable {
	// id represents PID
	var id: Int
	var processName: String
	var memoryUsage: Float
//	var cpuUsage: Float
}
