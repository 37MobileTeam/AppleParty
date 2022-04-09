//
//  ITCResponseModel.swift
//  AppleParty
//
//  Created by 易承 on 2021/5/13.
//
//  HTTP请求返回的数据解析类

import Foundation
import Cocoa


/*  消耗型项目consumable
    非消耗型non-consumable
    自动续期订阅auto-renewable
    非续期订阅subscription
 */
//  上传的商品类型
enum InAppPurchaseType: String {
    case CONSUMABLE = "consumable"
    case NON_CONSUMABLE = "non-consumable"
    case AUTO_RENEWABLE = "auto-renewable"
    case FREE_SUBSCRIPTION = "free-subscription"
    case SUBSCRIPTION = "subscription"
    case UNKNOW = "unknown"
    
    func CNValue() -> String {
        switch self {
        case .CONSUMABLE:
            return "消耗型"
        case .NON_CONSUMABLE:
            return "非消耗型"
        case .SUBSCRIPTION:
            return "非续订型"
        case .AUTO_RENEWABLE:
            return "自动续订型"
        case .FREE_SUBSCRIPTION:
            return "免费订阅型"
        default:
            return "未知"
        }
    }
}


/*
    "ITC.addons.type.consumable": "消耗型项目",
     "ITC.addons.type.freeSubscription": "免费订阅",
     "ITC.addons.type.nonConsumable": "非消耗型项目",
     "ITC.addons.type.recurring": "自动续期订阅",
     "ITC.addons.type.subscription": "非续期订阅",
 */
// 苹果后台商品类型
enum ITCAddOnType: String {
    case consumable = "ITC.addons.type.consumable"
    case subscription = "ITC.addons.type.subscription"
    case free_subscription = "ITC.addons.type.freeSubscription"
    case non_consumable = "ITC.addons.type.nonConsumable"
    case auto_renewable = "ITC.addons.type.recurring"
    case unknown
    
    func CNValue() -> String {
        switch self {
        case .consumable:
            return "消耗型项目"
        case .non_consumable:
            return "非消耗型项目"
        case .subscription:
            return "非续期订阅"
        case .auto_renewable:
            return "自动续期订阅"
        case .free_subscription:
            return "免费订阅"
        default:
            return "未知"
        }
    }
}


/*
 "approved": "已批准",
 "created": "已创建",
 "deleted": "已删除",
 "deletePending": "正在删除",
 "developerActionNeeded": "需要开发人员操作",
 "developerRemovedFromSale": "被开发人员下架",
 "developerSignedOff": "开发人员签名",
 "inReview": "正在审核",
 "missingMetadata": "元数据丢失",
 "pendingBinaryApproval": "正在审核",
 "pendingDeveloperRelease": "等待开发人员发布",
 "pendingScreenshot": "正在等待屏幕快照",
 "prepareForSubmission": "准备提交",
 "processingContentUpload": "正在处理",
 "readyForSale": "已批准",
 "readyToSubmit": "准备提交",
 "rejected": "被拒绝",
 "removedFromSale": "被下架",
 "replaced": "被替换",
 "waitingForContentUpload": "正在等待上传",
 "waitingForReview": "正在等待审核",
 */
// iap状态
enum InAppPurchaseState: String {
    case readyForSale
    case missingMetadata
    case developerActionNeeded
    case developerRemovedFromSale
    case readyToSubmit
    case prepareForSubmission
    case waitingForReview
    case waitingForContentUpload
    case inReview
    case pendingBinaryApproval
    case pendingDeveloperRelease
    case rejected
    case removedFromSale
    case approved
    case created
    case deleted
    case deletePending
    case developerSignedOff
    case pendingScreenshot
    case processingContentUpload
    case replaced
    case unknown
    
    var statusValue: (String, NSColor) {
        switch self {
        case .readyForSale:
            return ("可供销售", NSColor(calibratedRed: 0.23, green: 0.64, blue: 0.40, alpha: 1.00))
        case .missingMetadata:
            return ("元数据丢失", NSColor(calibratedRed: 0.97, green: 0.50, blue: 0.19, alpha: 1.00))
        case .developerActionNeeded:
            return ("需要开发人员操作", NSColor(calibratedRed: 0.95, green: 0.00, blue: 0.13, alpha: 1.00))
        case .developerRemovedFromSale:
            return ("被开发人员下架", NSColor(calibratedRed: 0.95, green: 0.00, blue: 0.13, alpha: 1.00))
        case .readyToSubmit, .prepareForSubmission:
            return ("准备提交", NSColor(calibratedRed: 0.23, green: 0.64, blue: 0.40, alpha: 1.00))
        case .waitingForReview:
            return ("正在等待审核", NSColor(calibratedRed: 0.900, green:0.658, blue:0.625, alpha:1.000))
        case .waitingForContentUpload:
            return ("正在等待上传", NSColor(calibratedRed: 0.23, green: 0.64, blue: 0.40, alpha: 1.00))
        case .inReview, .pendingBinaryApproval:
            return ("正在审核", NSColor(calibratedRed: 0.999, green:0.775, blue:0.031, alpha:1.000))
        case .pendingDeveloperRelease:
            return ("等待开发人员发布", NSColor(calibratedRed: 0.23, green: 0.64, blue: 0.40, alpha: 1.00))
        case .rejected:
            return ("被拒绝", NSColor(calibratedRed:0.548, green:0.145, blue:0.781, alpha:1.000))
        case .removedFromSale:
            return ("被下架", NSColor(calibratedRed:0.906, green:0.148, blue:0.155, alpha:1.000))
        default:
            return (self.rawValue, NSColor.secondaryLabelColor)
        }
    }
}

// MARK: - 内购列表-新
struct Product {
    var type: String = ""
    var id: String = ""
    var referenceName: String = ""
    var productId: String = ""
    var inAppPurchaseType: InAppPurchaseType = .UNKNOW
    var state: InAppPurchaseState = .unknown
}

struct ProductList {
    var products: [Product]
    
    init(body: [String: Any]) {
        products = [Product]()
        let data = dictionaryArray(body["data"])
        for temp in data {
            var product = Product()
            product.type = string(from: temp["type"])
            product.id = string(from: temp["id"])
            let attributes = dictionary(temp["attributes"])
            product.referenceName = string(from: attributes["referenceName"])
            product.productId = string(from: attributes["productId"])
            product.inAppPurchaseType = InAppPurchaseType(rawValue: string(from: attributes["inAppPurchaseType"])) ?? .UNKNOW
            product.state = InAppPurchaseState(rawValue: string(from: attributes["state"])) ?? .unknown
            products.append(product)
        }
    }
}

// MARK: - 内购列表-旧
struct IAPList {
    struct IAP {
        struct Version {
            var screenshotUrl: String = ""
            var itunesConnectStatus: String = ""
            var issuesCount: Int = 0
            var canSubmit: Bool = false
            
            init(dict: [String: Any]) {
                screenshotUrl = string(from: dict["screenshotUrl"])
                itunesConnectStatus = string(from: dict["itunesConnectStatus"])
                issuesCount = int(from: dict["issuesCount"]) ?? 0
                canSubmit = bool(from: dict["canSubmit"])
            }
        }
        
        struct ReviewScreenshot {
            var url: String = ""
            var thumbNailUrl: String = ""
            var originalFileName: String = ""
            var checksum: String = ""
            var width: Int = 0
            var height: Int = 0
            
            init(dict: [String: Any]) {
                let value = dictionary(dict["value"])
                width = int(from: value["width"]) ?? 0
                height = int(from: value["height"]) ?? 0
                checksum = string(from: value["checksum"])
                originalFileName = string(from: value["originalFileName"])
                url = string(from: value["url"])
                thumbNailUrl = string(from: value["thumbNailUrl"])
            }
        }

        var familyReferenceName: String = ""
        var durationDays: Int = 0
        var numberOfCodes: Int = 0
        var maximumNumberOfCodes: Int = 0
        var appMaximumNumberOfCodes: Int = 0
        var isEditable: Bool = false
        var isRequired: Bool = false
        var canDeleteAddOn: Bool = false
        var errorKeys: String = ""
        var itcsubmitNextVersion: Bool = false
        var isEmptyValue: Bool = false
        var adamId: String = ""                     // appleid
        var referenceName: String = ""              // 商品名称
        var vendorId: String = ""                   // 商品id
        var addOnType: ITCAddOnType = .unknown       // 商品类型
        var versions: [Version] = []
        var purpleSoftwareAdamIds: [String] = []
        var lastModifiedDate: String = ""
        var isNewsSubscription: Bool = false
        var iTunesConnectStatus: InAppPurchaseState = .unknown
        
        // detail
        var publicId: String = ""
        var tierStem: String = ""                   // 价格等级
        var country: String = ""                    // 价格地区
        var description: String = ""                // 商品描述
        var localeCode: String = ""                 // 地区代码
        var status: String = ""                     // 状态
        var reviewScreenshot: ReviewScreenshot?     // 截图
        
        mutating func updateDetail(body: [String: Any]) {
            let data = dictionary(body["data"])
            publicId = string(from: data["publicId"])
            tierStem = string(from: dictionary(dictionaryArray(data["pricingIntervals"]).first?["value"])["tierStem"])
            country = string(from: dictionary(dictionaryArray(data["pricingIntervals"]).first?["value"])["country"])
            description = string(from: dictionary(dictionary(dictionaryArray(dictionary(dictionaryArray(data["versions"]).first?["details"])).first?["value"])["description"])["value"])
            localeCode = string(from: (dictionary(dictionaryArray(dictionary(dictionaryArray(data["versions"]).first?["details"])).first?["value"])["localeCode"]))
            status = string(from: (dictionary(dictionaryArray(dictionary(dictionaryArray(data["versions"]).first?["details"])).first?["value"])["status"]))
            reviewScreenshot = ReviewScreenshot(dict: dictionary(dictionaryArray(data["versions"]).first?["reviewScreenshot"]))
        }
        
        /// 本地属性
        var isSelected = false                      // 是否标记为批量选中
        var curid = 0                               // 数组中的序号
        
        var app: App
        init(app: App) {
            self.app = app
        }
    }
    
    var iapList: [IAP]
    var app: App
    
    init(body: [String: Any], app: App) {
        iapList = [IAP]()
        let data = dictionaryArray(body["data"])
        for i in 0..<data.count {
            let temp = data[i]
            var iap = IAP(app: app)
            iap.curid = i+1
            iap.familyReferenceName = string(from: temp["familyReferenceName"])
            iap.durationDays = int(from: temp["durationDays"]) ?? 0
            iap.numberOfCodes = int(from: temp["numberOfCodes"]) ?? 0
            iap.maximumNumberOfCodes = int(from: temp["maximumNumberOfCodes"]) ?? 0
            iap.appMaximumNumberOfCodes = int(from: temp["appMaximumNumberOfCodes"]) ?? 0
            iap.isEditable = bool(from: temp["isEditable"])
            iap.isRequired = bool(from: temp["isRequired"])
            iap.canDeleteAddOn = bool(from: temp["canDeleteAddOn"])
            iap.errorKeys = string(from: temp["errorKeys"])
            iap.itcsubmitNextVersion = bool(from: temp["itcsubmitNextVersion"])
            iap.isEmptyValue = bool(from: temp["isEmptyValue"])
            iap.adamId = string(from: temp["adamId"])
            iap.referenceName = string(from: temp["referenceName"])
            iap.vendorId = string(from: temp["vendorId"])
            iap.addOnType = ITCAddOnType(rawValue: string(from: temp["addOnType"])) ?? .unknown
            
            let verArr = dictionaryArray(temp["versions"])
            for ver in verArr {
                let newVer = IAP.Version(dict: ver)
                iap.versions.append(newVer)
            }
            iap.purpleSoftwareAdamIds = stringArray(temp["purpleSoftwareAdamIds"])
            
            iap.lastModifiedDate = string(from: temp["lastModifiedDate"])
            iap.isNewsSubscription = bool(from: temp["isNewsSubscription"])
            iap.iTunesConnectStatus = InAppPurchaseState(rawValue: string(from: temp["iTunesConnectStatus"])) ?? .unknown
            iapList.append(iap)
        }
        
        // 简单排序
        iapList = iapList.sorted(by: { (iap1, iap2) -> Bool in
            let nonDigits = CharacterSet.decimalDigits.inverted
            let numStr1 = iap1.vendorId.trimmingCharacters(in: nonDigits)
            let numStr2 = iap2.vendorId.trimmingCharacters(in: nonDigits)
            return int(from: numStr1) ?? 0 < int(from: numStr2) ?? 0
        })
        self.app = app
    }
}

