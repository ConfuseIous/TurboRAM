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
		
		print(output)
		
		// Remove all empty strings
//		var columns = output.components(separatedBy: " ")
//
//		for (indecolumns, l) in columns.enumerated() {
//			columns[indecolumns] = l.trimmingCharacters(in: .whitespacesAndNewlines)
//		}
//
//		columns = columns.filter { $0 != "" }
		
		// Remove headings
//		if let index = columns.firstIndex(where: {$0.contains("KSHRD")}) {
//			columns.removeSubrange(0...index)
//		}
		
		// print(columns)
		
		// Each row has 36 columns
//		let numRows: Float = (Float(columns.count)/36)
//
//		print(numRows, columns.count)
		
		//		for i in 0...numRows {
//		for i in 0...10 {
//			//			print("i", i, "PROCESS:", columns[i * 35], "PID:", columns[(i * 35) + 1], "MEMORY:", columns[(i * 35) + 6])
//			print("i", i, "PROCESS:", columns[i * 36])
//		}
//
//		print(columns[4 * 36])
//		print(columns[(4 * 36) + 1])
		
		//		for i in 0...34 {
		//			print(columns[i])
		//		}
		
		// The first column represnts the process name and the seventh column represents memory
		//		print("PROCESS:", columns[0], "MEMORY:", columns[6])
		
		// let y = [[]]
		
		// for (index, l) in columns.enumerated() {
		//
		// }
		
//		return columns
		return []
	}
}
