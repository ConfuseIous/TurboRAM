//
//  MemoryInfo.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 14/11/22.
//

import AppKit
import Foundation

struct MemoryInfo {
	static func getMemoryInfo() -> [String]? {
		let task = Process()
		let pipe = Pipe()
		//		task.launchPath = "/usr/bin/top"
		//		task.arguments = ["-o", "mem", "-l", "1"]
		task.launchPath = "/bin/ps"
		task.arguments = ["-f", "-v", "-A"]
		task.standardOutput = pipe
		try? task.run()
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		print("data", data)
		print(task.standardError.debugDescription)
		print(task.terminationReason)
		print(task.terminationStatus)
		
		let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
		return [output]
		
		
		// Get all running applications
		//		let workspace = NSWorkspace.shared
		//		let applications = workspace.runningApplications
		//
		//		for app in applications {
		//			print(app.processIdentifier)
		//		}
		
		//		return [""]
	}
}
