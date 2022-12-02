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
		task.arguments = ["-o", "mem", "-l", "1", "-stats", "command,mem,pid"]
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
			var currentProcess = ProcessDetails(id: 0, processName: "", memoryUsage: 0)
			
			var currentProperty = 0
			var propertyString = ""
			
			let reversedColumn = column.reversed()
			
			for (index, character) in reversedColumn.enumerated() {
				propertyString += String(character)
				// Go backwards until you find a space
				if character == " " && reversedColumn[reversedColumn.index(reversedColumn.startIndex, offsetBy: index - 1)] != " " {
					if currentProperty == 0 {
						// Find process PID
						currentProcess.id = Int(String(propertyString.reversed()).trimmingCharacters(in: .whitespacesAndNewlines))!
						currentProperty += 1
					} else {
						// Find Process Name
						let processNameEndIndex = column.index(column.endIndex, offsetBy: (-1 * (index + 1)))
						
						let processName = String(column[...processNameEndIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
						
						// Calculate Memory Usage in MB
						propertyString = String(propertyString.reversed()).trimmingCharacters(in: .whitespacesAndNewlines)
						
						let memoryUsageStringIndex = propertyString.index(propertyString.endIndex, offsetBy: ((String(currentProcess.id).count) * -1) - 1)
						propertyString = String(propertyString[..<memoryUsageStringIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
						
						let memoryUsageIndex = propertyString.index(propertyString.endIndex, offsetBy: -1)
						let memoryUsageString = String(propertyString[..<memoryUsageIndex])
						var memoryUsage = Float(memoryUsageString)!
						
						if propertyString.last == "K" {
							memoryUsage /= 1000
						}
						
						currentProcess.processName = processName
						currentProcess.memoryUsage = memoryUsage
						
						processes.append(currentProcess)
						break
					}
				}
			}
		}
		
		return processes
	}
}
