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
	@Published var offendingProcesses: [ProcessDetails] = []
	@Published var ignoredProcessIDs: [Int] = []
	
	init() {
		reloadMemoryInfo()
		self.ignoredProcessIDs = getPermanentlyIgnoredProcessIDs()
	}
	
	func verifyScriptFile(completion: @escaping (Bool) -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.applicationScriptsDirectory, .userDomainMask, true)[0]
			let shellScript = path + "/script.sh"
			
			guard FileManager.default.fileExists(atPath: shellScript) else {
				completion(false)
				return
			}
			
			guard ((try? NSUserUnixTask(url: URL(fileURLWithPath: shellScript))) != nil) else {
				completion(false)
				return
			}
			
			completion(true)
		}
	}
	
	func reloadMemoryInfo() {
		// Create new thread to run script
		DispatchQueue.global(qos: .userInitiated).async {
			let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.applicationScriptsDirectory, .userDomainMask, true)[0]
			let shellScript = path + "/script.sh"
			
			// Show an error if the script doesn't exist
			guard FileManager.default.fileExists(atPath: shellScript) else {
				print("Script not found at \(shellScript)")
				return
			}
			
			// Use NSUserUnixTask to run the script
			guard let unixScript = try? NSUserUnixTask(url: URL(fileURLWithPath: shellScript)) else {
				return
			}

			// Get the output of the script to a variable
			let pipe = Pipe()
			unixScript.standardOutput = pipe.fileHandleForWriting
			
			unixScript.execute(withArguments: []) { error in
				if let error {
					print("Failed: ", error)
					return
				}
				
				let output = String(data: pipe.fileHandleForReading.availableData, encoding: .utf8)!
				
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
				
				//		var sum = Float(0)
				//		for process in processes {
				//			sum += process.memoryUsage
				//		}
				
				//		print("TOTAL RAM USED:", sum)
  
				self.initialValues.merge(processes.reduce(into: [Int: Float]()) {
					$0[$1.id] = $1.memoryUsage
				}, uniquingKeysWith: { (current, _) in current })
				
				/*
				 { (current, _) in current } is a closure that is passed as an argument to the merge method of the dictionary. The merge method takes a closure that defines how to merge the values of duplicate keys.
				 In this case, the closure takes two arguments, current and _, where current is the current value of the key in the initialValues dictionary and _ is the value of the key from the newProcesses dictionary.
				 The closure just returns the current value, which means that if there is a duplicate key in the newProcesses dictionary, the value of that key in the initialValues dictionary will be retained and the value in the newProcesses dictionary will be ignored.
				 It's an inline way of telling the function to keep the current value if there's a duplicate key.
				 */
				
				DispatchQueue.main.async {
					self.processes = processes
				}
			}
		}
	}
	
	
	func findOffendingProcesses() {
		// Returns all processes that grew memory usage by at least 50% since the first run and are using at least 500MB
		let commonProcesses: [ProcessDetails] = processes.filter({
			let proc = $0
			return (!ignoredProcessIDs.contains(where: {$0 == proc.id}) && $0.memoryUsage >= UserDefaults.standard.float(forKey: "minimumMemoryUsageThreshold"))
		}).compactMap { process in
			guard let compared = initialValues[process.id], process.memoryUsage >= (compared * UserDefaults.standard.float(forKey: "minimumMemoryUsageminimumMultiplier")) else { return nil }
			return process
		}
		
		self.offendingProcesses = commonProcesses
		print("FOUND \(self.offendingProcesses.count) OFFENDING PROCESSES")
	}
	
	func quitProcessWithPID(pid: Int) {
		let task = Process()
		let pipe = Pipe()
		
		/* kill requires breaking the sandbox.
		 killall does not, but requires the process name instead of PID.
		 */
		
		//		task.launchPath = "/bin/kill"
		//		task.arguments = [String(pid)]
		//		task.standardOutput = pipe
		
		// Get process name by PID
		task.launchPath = "/bin/bash"
		task.arguments = ["-c", "ps -p \(pid) -o comm= | awk -F/ '{print $NF}'"]
		
		task.standardOutput = pipe
		task.launch()
		
		let data = pipe.fileHandleForReading.readDataToEndOfFile()
		if let processName = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) {
			kill(processName: processName)
		}
		
		func kill(processName: String) {
			let task = Process()
			let pipe = Pipe()
			
			task.launchPath = "/usr/bin/killall"
			task.arguments = [processName]
			task.standardOutput = pipe
			
			try? task.run()
		}
		
		try? task.run()
	}
	
	func getPermanentlyIgnoredProcessIDs() -> [Int] {
		var ignoredProcessIDs: [Int] = []
		
		let ignoredProcessNames = UserDefaults.standard.array(forKey: "ignoredProcessNames") as? [String] ?? []
		for name in ignoredProcessNames {
			if let process = processes.first(where: {$0.processName == name}) {
				ignoredProcessIDs.append(process.id)
			}
		}
		
		return ignoredProcessIDs
	}
}
