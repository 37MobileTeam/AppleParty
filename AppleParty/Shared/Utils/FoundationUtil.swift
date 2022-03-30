//
//  FoundationUtil.swift
//  AppleParty
//
//  Created by HTC on 2022/3/17.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import AppKit
import Cocoa
import CommonCrypto


// MARK: - Extension
// refer: https://stackoverflow.com/questions/27327067/append-text-or-data-to-text-file-in-swift
extension String {
    
    func appendLine(to url: URL) throws {
        try self.appending("\n").append(to: url)
    }
    func append(to url: URL) throws {
        let data = self.data(using: String.Encoding.utf8)
        try data?.append(to: url)
    }
    
    func trim() -> String {
        var resultString = self.trimmingCharacters(in: CharacterSet.whitespaces)
        resultString = resultString.trimmingCharacters(in: CharacterSet.newlines)
        return resultString
    }
    
    func matchRegex(regex: String, options: NSRegularExpression.Options = []) -> Bool {
        guard let re = try? NSRegularExpression(pattern: regex, options: options) else {
            return false
        }
        return re.firstMatch(in: self, options: [], range: NSMakeRange(0, utf16.count)) != nil
    }
}

extension Data {
    func append(to url: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: url) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        } else {
            try write(to: url)
        }
    }
}

// MARK: - Unicode string
// refer: https://github.com/Geniune/SwiftUnicode/blob/master/ObjectUnicode.swift
extension Array {
    var unicodeDescription : String {
        return self.description.stringByReplaceUnicode
    }
}

extension Dictionary {
   var unicodeDescription : String{
        return self.description.stringByReplaceUnicode
    }
}

extension String {
    var unicodeDescription : String{
        return self.stringByReplaceUnicode
    }
    
    var stringByReplaceUnicode : String{
        let tempStr1 = self.replacingOccurrences(of: "\\u", with: "\\U")
        let tempStr2 = tempStr1.replacingOccurrences(of: "\"", with: "\\\"")
        let tempStr3 = "\"".appending(tempStr2).appending("\"")
        let tempData = tempStr3.data(using: String.Encoding.utf8)
        var returnStr:String = ""
        do {
            returnStr = try PropertyListSerialization.propertyList(from: tempData!, options: [.mutableContainers], format: nil) as! String
        } catch {
            print(error)
        }
        return returnStr.replacingOccurrences(of: "\\n", with: "\n")
    }
}

extension URL {
    
    func fileMD5() -> String? {
        let bufferSize = 1024 * 1024
        do {
            //打开文件
            let file = try FileHandle(forReadingFrom: self)
            defer {
                file.closeFile()
            }
            
            //初始化内容
            var context = CC_MD5_CTX()
            CC_MD5_Init(&context)
            
            //读取文件信息
            while case let data = file.readData(ofLength: bufferSize), data.count > 0 {
                data.withUnsafeBytes {
                    _ = CC_MD5_Update(&context, $0, CC_LONG(data.count))
                }
            }
            
            //计算Md5摘要
            var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes {
                _ = CC_MD5_Final($0, &context)
            }
            
            return digest.map { String(format: "%02hhx", $0) }.joined()
            
        } catch {
            print("Cannot open file:", error.localizedDescription)
            return nil
        }
    }
    
    func fileSize() -> String {
        if let fileData:Data = try? Data.init(contentsOf: self) {
            return String(fileData.count)
        }
        return "0"
    }
    
    
}

extension Collection {
    var isNotEmpty: Bool { return !isEmpty }
}

/// 进行类型转换获取字符串类型值
func string(from value: Any?, defaultValue: String = "") -> String {
    if let str = value as? String {
        return str
    } else if let int = value as? Int {
        return int.description
    } else if let double = value as? Double {
        return double.description
    } else if let float = value as? Float {
        return float.description
    } else {
        return defaultValue
    }
}


/// 进行类型转换获取Int类型值
func int(from value: Any?) -> Int? {
    if let num = value as? Int {
        return num
    } else if let num = value as? String {
        return Int(num)
    } else {
        return nil
    }
}

/// 判断字符串类型转化为bool值，1代表true，其他代表false
func bool(from value: Any?) -> Bool {
    if let str = value as? String {
        if str == "1" {
            return true
        }
    }
    if let num = value as? Int {
        if num == 1 {
            return true
        }
    }

    if let boo = value as? Bool {
        return boo
    }
    return false
}

/// 进行类型转换获取[String: Any]类型值
func dictionary(_ origin: Any?) -> [String: Any] {
    return origin as? [String: Any] ?? [:]
}

func dictionaryArray(_ origin: Any?) -> [[String: Any]] {
    return origin as? [[String: Any]] ?? [[String: Any]]()
}

func stringArray(_ origin: Any?) -> [String] {
    return origin as? [String] ?? []
}

/// 校验邮箱地址
func isEmailValid(_ str: String) -> Bool {
    guard str.matchRegex(regex: "^.+@.+\\..+$") else {
        return false
    }
    return true
}

func currentView() -> NSView {
    if let rootView = NSApplication.shared.keyWindow?.contentViewController?.view {
        return rootView
    }

    if let delegate = NSApplication.shared.delegate as? AppDelegate {
        return delegate.mainWindow?.contentView ?? NSView()
    }

    debugPrint("Fatal error: window or keyWindow is nil")
    return NSView()
}
