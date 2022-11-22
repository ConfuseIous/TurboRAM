//
//  MemoryInfo.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 14/11/22.
//

import AppKit
import Foundation

struct MemoryInfo {
	static func getMemoryInfo() -> [ProcessDetails] {
		let task = Process()
		let pipe = Pipe()
		
		/* While both top and ps should work in theory, ps seems to underreport memory in practice.
		 Rely on top instead.
		 */
		
		//		task.launchPath = "/bin/ps"
		//		task.arguments = ["-f", "-v", "-A"]

		task.launchPath = "/usr/bin/top"
		task.arguments = ["-o", "mem", "-l", "1", "-stats", "command,mem"]
		task.standardOutput = pipe
		try? task.run()
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		
		// DEBUG
		// print(task.standardError.debugDescription)
		// print(task.terminationReason)
		// print(task.terminationStatus)
		//
		
		let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
		
		var columns = output.components(separatedBy: "\n")

		for (indecolumns, l) in columns.enumerated() {
			columns[indecolumns] = l.trimmingCharacters(in: .whitespacesAndNewlines)
		}

		// Remove empty columns
		columns = columns.filter { $0 != "" }
		
		// Remove headings
		if let index = columns.firstIndex(where: {$0.contains("MEM")}) {
			columns.removeSubrange(0...index)
		}
		
		var processes: [ProcessDetails] = []
		
		for column in columns {
			var memoryUsageString = ""
			
			// Go backwards until you find a space
			for (index, character) in column.reversed().enumerated() {
				memoryUsageString.append(character)
				if character == " " {
					// Find Process Name
					let processNameEndIndex = column.index(column.endIndex, offsetBy: (-1 * (index + 1)))
					let processName = String(column[...processNameEndIndex])
					
					// Calculate Memory Usage in MB
					memoryUsageString = String(memoryUsageString.reversed()).trimmingCharacters(in: .whitespacesAndNewlines)
					
					let memoryUsageStringIndex = memoryUsageString.index(memoryUsageString.endIndex, offsetBy: -1)
					var memoryUsage = Float(String(memoryUsageString[..<memoryUsageStringIndex]))!
					
					if memoryUsageString.last == "K" {
						memoryUsage /= 1000
					}
					
					processes.append(ProcessDetails(processName: processName, memoryUsage: memoryUsage))
					break
				}
			}
		}
		
		return processes
	}
}
