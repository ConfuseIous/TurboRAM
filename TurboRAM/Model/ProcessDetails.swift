//
//  ProcessDetails.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 20/11/22.
//

import Foundation

struct ProcessDetails: Identifiable, Equatable {
	var id: Int
	var processName: String
	var memoryUsage: Float
}
