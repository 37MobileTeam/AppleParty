//
//  XMLManager.swift
//  AppleParty
//
//  Created by 易承 on 2021/5/25.
//

import Foundation

class XMLManager {
    
    static let appPtah = "/AppleParty/InAppPurches/"
    static let shotPtah = "/AppleParty/ScreenShots/"
    
    static func getITMSPath(_ appid: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let filePath = documentsDirectory + appPtah + appid + ".itmsp"
        return filePath
    }
    
    static func getShotsPath(_ appid: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let filePath = documentsDirectory + shotPtah + appid + ".itmsp"
        return filePath
    }
    
    static func verifyITMS(account: String, pwd: String, filePath: String) -> (Int32, String?) {
        return runShellWithArgsAndOutput(launchPath: iTMSTransporter, "-f", filePath, "-m", "verify", "-u", account, "-p", pwd)
    }
    
    static func uploadITMS(account: String, pwd: String, filePath: String) -> (Int32, String?) {
        return runShellWithArgsAndOutput(launchPath: iTMSTransporter, "-f", filePath, "-m", "upload", "-u", account, "-p", pwd)
    }
    
    static func deleteITMS(_ filePath:String) {
        do {
            let fileManager = FileManager.default
            // Check if file or directory exists
            if fileManager.fileExists(atPath: filePath) {
                // Delete file or directory
                try fileManager.removeItem(atPath: filePath)
            } else {
                print("File does not exist: \(filePath)")
            }
        } catch {
            print("File An error took place: \(error)")
        }
    }
    
    static func openDocuments() {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        runShellWithArgs(launchPath: "open", documentsDirectory)
    }
    
    static func copySimpleExel() {
        if let xlsxPath = Bundle.main.path(forResource: "sample", ofType: "xlsx") {
            let dateFormatter : DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let currentDate = dateFormatter.string(from: Date())
            try? FileManager.default.copyItem(atPath: xlsxPath, toPath: NSHomeDirectory()+"/Desktop/IAP-\(currentDate).xlsx")
        }
        runShellWithArgs(launchPath: "/usr/bin/open", NSHomeDirectory()+"/Desktop/")
    }
}

// MARK: - Shell命令
let iTMSTransporter = "/Applications/Transporter.app/Contents/itms/bin/iTMSTransporter"
let shell = "/usr/bin/env"

@discardableResult
func runShellWithArgs(launchPath: String, _ args: String...) -> Int32 {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = args
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

func runShellWithArgsAndOutput(launchPath: String, _ args: String...) -> (Int32, String?) {
    let task = Process()
    task.launchPath = launchPath
    task.arguments = args
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)
    task.waitUntilExit()
    return (task.terminationStatus, output)
}
