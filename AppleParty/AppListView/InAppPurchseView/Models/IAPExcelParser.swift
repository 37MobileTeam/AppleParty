//
//  IAPExcelParser.swift
//  AppleParty
//
//  Created by HTC on 2022/11/10.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Foundation
import CoreXLSX


/// 上传的商品类型
enum IAPType: String {
    case CONSUMABLE = "CONSUMABLE"
    case NON_CONSUMABLE = "NON_CONSUMABLE"
    case NON_RENEWING_SUBSCRIPTION = "NON_RENEWING_SUBSCRIPTION"
    case AUTO_RENEWABLE = "auto-renewable"
    case UNKNOW = "unknown"
    
    static func type(name: String) -> IAPType {
        switch name {
        case "消耗型":
            return .CONSUMABLE
        case "非消耗型":
            return .NON_CONSUMABLE
        case "非续期订阅":
            return .NON_RENEWING_SUBSCRIPTION
        case "自动续期订阅":
            return .AUTO_RENEWABLE
        default:
            return .UNKNOW
        }
    }
    
    func CNValue() -> String {
        switch self {
        case .CONSUMABLE:
            return "消耗型"
        case .NON_CONSUMABLE:
            return "非消耗型"
        case .NON_RENEWING_SUBSCRIPTION:
            return "非续期订阅"
        case .AUTO_RENEWABLE:
            return "自动续期订阅"
        default:
            return "未知"
        }
    }
}

struct IAPLocalization {
    var name: String = ""
    var description: String = ""
    var locale: String = ""
}

// 订阅类型的子字段
struct IAPSubscriptions {
    var groupLevel: Int = 1
    var subscriptionPeriod: String = "ONE_MONTH" //ONE_WEEK, ONE_MONTH, TWO_MONTHS, THREE_MONTHS, SIX_MONTHS, ONE_YEAR
}

struct IAPProduct {
    var name: String = ""
    var productId: String = ""
    var priceTier: String = ""
    var reviewNote: String = ""
    var reviewScreenshot: String = ""
    var familySharable: Bool = false
    var availableInAllTerritories: Bool = true
    var inAppPurchaseType: IAPType = .UNKNOW  //# CONSUMABLE、NON_CONSUMABLE、NON_RENEWING_SUBSCRIPTION
    var localizations: [IAPLocalization] = []
    // 检查价格
    var price: String = ""
    // 订阅类型的特有
    var subscriptions: IAPSubscriptions?
}


struct IAPExcelParser {
    
    static func parser(_ filePath: URL) -> [IAPProduct] {
        guard let file = XLSXFile(filepath: filePath.path) else {
          fatalError("XLSX file at \(filePath.path) is corrupted or does not exist")
        }
        
        var result: [IAPProduct] = []
        for wbk in try! file.parseWorkbooks() {
            for (name, path) in try! file.parseWorksheetPathsAndNames(workbook: wbk) {
                if let worksheetName = name {
                    print("This worksheet has a name: \(worksheetName)")
                }
                
                if name != "AppleParty" {
                    continue
                }
                
                guard let worksheet = try? file.parseWorksheet(at: path),
                      let sharedStrings = try! file.parseSharedStrings() else {
                    print("This worksheet/sharedStrings is null")
                    return result
                }
                var index = 0
                var columnTitles = [String]()
                var columnIndexs = [String]()
                for row in worksheet.data?.rows ?? [] {
                    var columnValues = [String: String]()
                    index += 1
                    for cell in row.cells {
                        let key = cell.reference.column.value
                        var columnStrings = cell.stringValue(sharedStrings) ?? ""
                        // 富文本读取
                        var richStr = ""
                        let richColumnCString = cell.richStringValue(sharedStrings)
                        for richChar in richColumnCString {
                            richStr += string(from: richChar.text)
                        }
                        columnStrings += richStr
                        // 第一行作为标识行，用于多语言标识，默认信任此字段
                        if index == 1 {
                            columnTitles.append(columnStrings)
                            columnIndexs.append(key)
                        } else {
                            columnValues[key] = columnStrings
                        }
                    }
                    
                    if index == 1 {
                        print(columnTitles)
                        print(columnIndexs)
                        continue
                    }
                    
                    // 金额(可选)  Product ID    参考名字    价格等级    内购买类型    审核截图(可选)    审核备注(可选)    zh-Hans    zh-Hans    ja    ja    ko    ko
                    var iap = IAPProduct()
                    iap.price = columnValues["A"] ?? ""
                    iap.productId = columnValues["B"] ?? ""
                    iap.name = columnValues["C"] ?? ""
                    let priceTier = columnValues["D"] ?? ""
                    iap.priceTier = checkPriceTier(priceTier)
                    let productType = columnValues["E"] ?? ""
                    iap.inAppPurchaseType = IAPType.type(name: productType)
                    iap.reviewScreenshot = columnValues["F"] ?? ""
                    iap.reviewNote = columnValues["G"] ?? ""
                    
                    // 非法的行
                    if iap.productId.isEmpty, iap.name.isEmpty {
                        continue
                    }
                    
                    // 【产品 ID】 可以由字母、数字、下划线（_）和句点（.）构成。 2 ~ 100 个字符）
                    if iap.productId.count < 2 || iap.productId.count > 100 {
                        NSAlert.show("Product ID 长度为：2~100 字符！")
                    }
                    // 参考名字
                    if iap.name.count < 2 || iap.name.count > 64 {
                        NSAlert.show("\(iap.productId)：“参考名字”长度超过 2~64 字符！")
                    }
                    
                    // 订阅类型默认的字段
                    if iap.inAppPurchaseType == .AUTO_RENEWABLE {
                        iap.subscriptions = IAPSubscriptions()
                    }
                    // 商品本地化名称和描述
                    var localizations: [IAPLocalization] = []
                    // 本地化的标识，从下标7开始，奇数遍历，成对出现的
                    let columeMax = columnIndexs.count
                    let columeEedIndex = columnIndexs.count - 1
                    for idx in stride(from: 7, to: columeEedIndex, by: 2){
                        if idx + 1 <= columeMax {
                            var localization = IAPLocalization()
                            let locale = columnTitles[idx]
                            localization.locale = locale
                            let key1 = columnIndexs[idx]
                            let key2 = columnIndexs[idx+1]
                            let name = columnValues[key1] ?? ""
                            let description = columnValues[key2] ?? ""
                            localization.name = name
                            localization.description = description
                            if !name.isEmpty && !description.isEmpty {
                                localizations.append(localization)
                            }
                            
                            // 商品本地化名称（必填） 2~30个字符
//                            if name.count < 2 || name.count > 30 {
//                                NSAlert.show("\(iap.productId)：“商品本地化名称”长度超过 2~30 字符！(\(locale))")
//                            }
//                            // 商品本地化描述（必填） 2~45个字符
//                            if description.count < 2 || description.count > 45 {
//                                NSAlert.show("\(iap.productId)：“商品本地化描述”长度超过 2~45 字符！(\(locale))")
//                            }
                        }
                    }
                    iap.localizations = localizations
                    result.append(iap)
                }
            }
        }
        return result
    }
    
    private static func checkPriceTier(_ priceTier: String) -> String {
        if priceTier.contains("A") {
            return "510"
        }
        if priceTier.contains("B") {
            return "530"
        }
        if priceTier.contains("备用1") {
            return "550"
        }
        if priceTier.contains("备用2") {
            return "560"
        }
        if priceTier.contains("备用3") {
            return "570"
        }
        if priceTier.contains("备用4") {
            return "580"
        }
        if priceTier.contains("备用5") {
            return "590"
        }
        return priceTier
    }

}
