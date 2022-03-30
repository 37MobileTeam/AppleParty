//
//  XLSXParser.swift
//  AppleParty
//
//  Created by 易承 on 2021/5/31.
//

import Foundation
import CoreXLSX

struct XLSXParser {
    
    static func parser(filePath: String) -> [[String]] {
        guard let file = XLSXFile(filepath: filePath) else {
            fatalError("XLSX file at \(filePath) is corrupted or does not exist")
        }
        
        for wbk in try! file.parseWorkbooks() {
            for (name, path) in try! file.parseWorksheetPathsAndNames(workbook: wbk) {
                if let worksheetName = name {
                    print("This worksheet has a name: \(worksheetName)")
                }
                
                if name != "Sheet1" {
                    continue
                }
                
                let worksheet = try! file.parseWorksheet(at: path)
                if let sharedStrings = try! file.parseSharedStrings() {
                    var xlsx = [[String]]()
                    let chars = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
                    for char in chars {
                        var columnCStrings = worksheet.cells(atColumns: [ColumnReference(char)!])
                            .map { string(from: $0.stringValue(sharedStrings)) }
                        let richColumnCStrings = worksheet.cells(atColumns: [ColumnReference(char)!])
                            .map { $0.richStringValue(sharedStrings) }
                        for i in 0..<columnCStrings.count {
                            let richArr = richColumnCStrings[i]
                            var richStr = ""
                            for richChar in richArr {
                                richStr += string(from: richChar.text)
                            }
                            columnCStrings[i] += richStr
                        }
                        xlsx.append(columnCStrings)
                    }
                    let pris = xlsx.filter { (column) -> Bool in
                        return column.filter { (value) -> Bool in
                            value == "金额"
                        }.isNotEmpty
                    }.first ?? xlsx[0]
                    let prods = xlsx.filter { (column) -> Bool in
                        return column.filter { (value) -> Bool in
                            value == "Product ID"
                        }.isNotEmpty
                    }.first ?? xlsx[1]
                    let names = xlsx.filter { (column) -> Bool in
                        return column.filter { (value) -> Bool in
                            value == "商品名称"
                        }.isNotEmpty
                    }.first ?? xlsx[2]
                    let levels = xlsx.filter { (column) -> Bool in
                        return column.filter { (value) -> Bool in
                            value == "Price Tier"
                        }.isNotEmpty
                    }.first ?? xlsx[3]
                    let dps = xlsx.filter { (column) -> Bool in
                        return column.filter { (value) -> Bool in
                            value == "商品描述"
                        }.isNotEmpty
                    }.first ?? xlsx[4]
                    let types = xlsx.filter { (column) -> Bool in
                        return column.filter { (value) -> Bool in
                            value == "内置购买类型"
                        }.isNotEmpty
                    }.first ?? xlsx[5]
                    let scrs = xlsx.filter { (column) -> Bool in
                        return column.filter { (value) -> Bool in
                            value == "截图"
                        }.isNotEmpty
                    }.first ?? xlsx[6]
                    let langs = xlsx.filter { (column) -> Bool in
                        return column.filter { (value) -> Bool in
                            value == "语言"
                        }.isNotEmpty
                    }.first ?? []

                    return [pris.filter({ $0 != "金额" }),
                            prods.filter({ $0 != "Product ID" }),
                            names.filter({ $0 != "商品名称" }),
                            levels.filter({ $0 != "Price Tier" }),
                            dps.filter({ $0 != "商品描述" }),
                            types.filter({ $0 != "内置购买类型" }),
                            scrs.filter({ $0 != "截图" }),
                            langs.filter({ $0 != "语言" })]
                }
            }
        }
        return []
    }
}
