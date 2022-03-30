//
//  APLogs.swift
//  AppleParty
//
//  Created by iHTC on 20210930.
//  Copyright © 2021 37 Mobile Games. All rights reserved.
//

import Foundation


class APLogs {
    static let shared = APLogs()
    
    func add(_ log: String, printlog: Bool = false, retry: Int = 3) {
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "[MM-dd HH:mm:ss] "
        let currentDateString = dateFormatter.string(from: Date())
        let out = currentDateString + log
        
        if printlog {
            debugPrint(out)
        }
        
        dateFormatter.dateFormat = "yyyyMMdd_HH00"
        let dataPath = dateFormatter.string(from: Date())
        
        var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        documentsURL.appendPathComponent("AppleParyty")
        documentsURL.appendPathComponent("Logs")
        documentsURL.appendPathComponent("\(dataPath)_log.txt")
        createFileDirectory(url: documentsURL)
        
        let path = documentsURL
        do {
            try out.appendLine(to: path)
        } catch {
            if retry > 0 {
                print("‼️ retry save logs file~ error:\(error)")
                add(log, printlog: printlog, retry: retry - 1)
            }
        }
    }
    
    
    func createFileDirectory(url: URL) {
        let fm = FileManager.default
        let directory = url.deletingLastPathComponent()
        var isDirectory: ObjCBool = false
        // 保证目录存在，不存在就创建目录
        if !(fm.fileExists(atPath: directory.path, isDirectory: &isDirectory) && isDirectory.boolValue) {
            do {
                try fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("‼️ create Directory file error:\(error), \(url.path)")
            }
        }
    }
    
    
}
