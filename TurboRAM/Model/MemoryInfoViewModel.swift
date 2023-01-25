//
//  MemoryInfoViewModel.swift
//  TurboRAM
//
//  Created by Karandeep Singh on 14/11/22.
//

import AppKit
import Foundation

class MemoryInfoViewModel: ObservableObject {
	
	var initialValues: [Int : Float] = [:] // Dictionary allows for 0(1) lookup time instead of 0(n)
	
	@Published var processes: [ProcessDetails] = []
	
	func reloadMemoryInfo() {
		let task = Process()
		let pipe = Pipe()
		
		
		//		task.launchPath = "/bin/ps"
		//		task.arguments = ["-f", "-v", "-A"]
		//		ps -ax -o vsize
		
		task.launchPath = "/usr/bin/top"
		task.arguments = ["-o", "mem", "-l", "1", "-stats", "command,mem,pid"]
		task.standardOutput = pipe
		try? task.run()
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		
		/* Activity Monitor and the top command use different methods to measure memory usage. Activity Monitor uses the virtual memory size of a process, which includes both the physical memory (RAM) used by the process and any additional space reserved for the process in the swap file. The top command, on the other hand, shows the "resident size" of a process, which is the amount of physical memory (RAM) being used by the process. This means that the memory usage reported by the top command will generally be lower than the usage reported by Activity Monitor.
		 */
		
		/*
		 The values reported by the ps command for memory usage will depend on the options used with the command. By default, ps will show the "resident size" of a process, which is the amount of physical memory (RAM) being used by the process. This is similar to the "RES" column shown by the top command.
		 
		 However, ps also has options that allow you to see the virtual memory size of a process, which includes both the physical memory used by the process and any additional space reserved for the process in the swap file. This is similar to the memory usage reported by Activity Monitor.
		 */
		
		// DEBUG
		// print(task.standardError.debugDescription)
		// print(task.terminationReason)
		// print(task.terminationStatus)
		//
		
		let output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
		
		//		print(output)
		
		var columns = output.components(separatedBy: "\n")
		
		for (index, l) in columns.enumerated() {
			columns[index] = l.trimmingCharacters(in: .whitespacesAndNewlines)
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
		
		var sum = Float(0)
		for process in processes {
			sum += process.memoryUsage
		}
		
		//		print("TOTAL RAM USED:", sum)
		
		if initialValues.isEmpty {
			self.initialValues = processes.reduce(into: [Int: Float]()) {
				$0[$1.id] = $1.memoryUsage
			}
			
			self.processes = processes
		}
	}
	
	func compareMemoryUsageToOriginal() -> [ProcessDetails] {
		// Returns all processes that grew memory usage by at least 20% since the first run
		let commonProcesses: [ProcessDetails] = processes.compactMap { process in
			guard let compared = initialValues[process.id], process.memoryUsage > (compared * 1.2) else { return nil }
			return process
		}
		
		return commonProcesses
	}
}

