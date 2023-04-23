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
    
    func md5() -> String {
        let cStr = self.cString(using: String.Encoding.utf8)
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 16)
        CC_MD5(cStr!, (CC_LONG)(strlen(cStr!)), buffer)
        let md5String = NSMutableString()
        for i in 0 ..< 16 {
            md5String.appendFormat("%02x", buffer[i])
        }
        free(buffer)
        return md5String as String
    }
    
    func prettyJSON(_ options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed] ) throws -> String? {
        let data = self.data(using: .utf8)!
        let obj = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        let jsonData = try JSONSerialization.data(withJSONObject: obj, options: options)
        let pretty = String(data: jsonData, encoding: .utf8)
        return pretty
    }
    
    // MARK: - 价格格式调整
    
    /// 返回保留2位小数的价格格式
    /// 因为苹果接口返回的价格可能是 "3"，"3.0" 或 "3.00"
    /// - Parameter price: 原价格
    /// - Returns: 保留2位小数的价格字符串
    func normalizePrice() -> String {
        let price = self
        let components = price.split(separator: ".")
        if components.count == 1 {
            return price + ".00"
        } else if components.count == 2 {
            let decimalPart = components[1]
            if decimalPart.count == 1 {
                return "\(components[0]).\(decimalPart)0"
            } else if decimalPart.count >= 2 {
                return "\(components[0]).\(decimalPart.prefix(2))"
            }
        }
        return price
    }
    
    /// 返回最多保留2位小数的价格格式
    /// 例如： "74.989999999999995 转换为 "74.99"
    /// - Returns: 超过2个小数位的会四舍五入，最终的价格格式可能示例： "3"，"3.0" 或 "3.00"
    func twoDecimalPrice() -> String {
        let input = self
        let parts = input.split(separator: ".")
        if parts.count == 2, parts[1].count > 2, let value = Double(input) {
            let roundedValue = round(value * 100) / 100
            return String(format: "%.2f", roundedValue)
        }
        
        return input
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
    var unicodeDescription : String {
        return self.stringByReplaceUnicode
    }
    
    var stringByReplaceUnicode : String {
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
    
    var createFilePath: URL {
        var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        documentsURL.appendPathComponent(self)
        // createFileDirectory
        let fm = FileManager.default
        let directory = documentsURL.deletingLastPathComponent()
        var isDirectory: ObjCBool = false
        // 保证目录存在，不存在就创建目录
        if !(fm.fileExists(atPath: directory.path, isDirectory: &isDirectory) && isDirectory.boolValue) {
            do {
                try fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("‼️ create Directory file error:\(error)")
            }
        }
        return documentsURL
        
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
    
    func fileSizeInt() -> Int {
        if let fileData: Data = try? Data.init(contentsOf: self) {
            return fileData.count
        }
        return 0
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

func debugLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    debugPrint(items, separator: separator, terminator: terminator)
    #endif
}
