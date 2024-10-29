//
//  AppStoreConnectAPI.swift
//  AppleParty
//
//  Created by HTC on 2022/11/14.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//
// refer: https://github.com/AvdLee/appstoreconnect-swift-sdk


import Foundation
import Combine
import AppStoreConnect_Swift_SDK


typealias ASCApp = AppStoreConnect_Swift_SDK.App
typealias ASCTerritory = AppStoreConnect_Swift_SDK.Territory

typealias ASCInAppPurchaseV2 = AppStoreConnect_Swift_SDK.InAppPurchaseV2
typealias ASCIAPPricePoint = AppStoreConnect_Swift_SDK.InAppPurchasePricePoint
typealias ASCIAPPriceSchedule = AppStoreConnect_Swift_SDK.InAppPurchasePriceSchedule
typealias ASCIAPLocalization = AppStoreConnect_Swift_SDK.InAppPurchaseLocalization
typealias ASCIAPScreenshot = AppStoreConnect_Swift_SDK.InAppPurchaseAppStoreReviewScreenshot
typealias ASCIAPAvailability = AppStoreConnect_Swift_SDK.InAppPurchaseAvailability

typealias ASCSubscription = AppStoreConnect_Swift_SDK.Subscription
typealias ASCSubscriptionPrice = AppStoreConnect_Swift_SDK.SubscriptionPrice
typealias ASCSubscriptionPricePoint = AppStoreConnect_Swift_SDK.SubscriptionPricePoint
typealias ASCSubscriptionLocalization = AppStoreConnect_Swift_SDK.SubscriptionLocalization
typealias ASCSubscriptionScreenshot = AppStoreConnect_Swift_SDK.SubscriptionAppStoreReviewScreenshot
typealias ASCSubscriptionGroup = AppStoreConnect_Swift_SDK.SubscriptionGroup
typealias ASCSubscriptionGroupLocale = AppStoreConnect_Swift_SDK.SubscriptionGroupLocalization
typealias ASCSubscriptionAvailability = AppStoreConnect_Swift_SDK.SubscriptionAvailability


class APASCAPI {
    
    public var updateMsg: (([String])->Void)?
    private var message = [String]() {
        didSet {
            updateMsg?(message)
        }
    }
    
    // 日志文件保存路径
    private let date = Date()
    var logPath: String {
        get {
            let dateFormatter : DateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
            let currentDate = dateFormatter.string(from: date)
            return "/AppleParty/ASCAPI/log_\(currentDate).txt"
        }
    }
    
    /// Go to https://appstoreconnect.apple.com/access/api and create your own key. This is also the page to find the private key ID and the issuer ID.
    /// Download the private key and open it in a text editor. Remove the enters and copy the contents over to the private key parameter.
    //private let configuration = APIConfiguration(issuerID: "<YOUR ISSUER ID>", privateKeyID: "<YOUR PRIVATE KEY ID>", privateKey: "<YOUR PRIVATE KEY>")
    //private lazy var provider: APIProvider = APIProvider(configuration: configuration)
    private var provider: APIProvider?
    private var rateLimitPublisher: AnyCancellable?
    
    init(issuerID: String, privateKeyID: String, privateKey: String, showApiRateLimit: Bool) {
        do {
            let configuration = try APIConfiguration(issuerID: issuerID, privateKeyID: privateKeyID, privateKey: privateKey)
            self.provider = APIProvider(configuration: configuration)
            if showApiRateLimit {
                self.rateLimitPublisher = self.provider?.rateLimitPublisher.sink(receiveValue: { [weak self]  rateLimit in
                    self?.handleError("接口速率限制：\(rateLimit.requestURL?.relativePath ?? ""), \(rateLimit.entries)")
                })
            }
        } catch {
            handleError("初始化失败: \(error.localizedDescription)")
        }
    }
    
    /// 获取所有 app
    /// - Returns: apps
    func apps() async -> [ASCApp]? {
        let request = APIEndpoint.v1.apps
            .get(parameters: .init(
                sort: [.bundleID],
                fieldsApps: [.appInfos, .name, .bundleID],
                limit: 200
            ))
        do {
            guard let provider = provider else {
                return nil
            }
            var allApps: [ASCApp] = []
            for try await pagedResult in provider.paged(request) {
                allApps.append(contentsOf: pagedResult.data)
            }
            return allApps
        } catch {
            handleError("获取app失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 获取所有 App Store 支持的国家或地区
    /// - Returns: apps
    func territories() async -> [ASCTerritory]? {
        let request = APIEndpoint.v1.territories
            .get(limit: 200)
        do {
            guard let provider = provider else {
                return nil
            }
            var allTerritorys: [ASCTerritory] = []
            for try await pagedResult in provider.paged(request) {
                allTerritorys.append(contentsOf: pagedResult.data)
            }
            return allTerritorys
        } catch {
            handleError("获取 App Store 支持的国家或地区失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - 非续期订阅类型内购 API
    
    /// 获取 app 所有的商品信息
    /// - Parameter appId: apple id
    /// - Returns: 商品列表
    func fetchInAppPurchasesList(appId: String) async -> [ASCInAppPurchaseV2] {
        let request = APIEndpoint.v1.apps.id(appId).inAppPurchasesV2
            .get(parameters: .init(
                limit: 200
            ))
        do {
            guard let provider = provider else {
                return []
            }
            var allIAPs: [ASCInAppPurchaseV2] = []
            for try await pagedResult in provider.paged(request) {
                allIAPs.append(contentsOf: pagedResult.data)
            }
            return allIAPs
        } catch {
            handleError("获取内购列表失败: \(error.localizedDescription)")
            return []
        }
        
    }
    
    /// 创建内购商品
    /// - Parameters:
    ///   - appId: apple id
    ///   - product: 内购商品信息
    /// - Returns: 成功时返回对应的商品信息
    func createInAppPurchases(appId: String, product: IAPProduct) async -> ASCInAppPurchaseV2? {
        let body = [
            "data": [
                "attributes": [
                    //"availableInAllTerritories": product.territories.availableInAllTerritories,
                    "familySharable": product.familySharable,
                    // CONSUMABLE、NON_CONSUMABLE、NON_RENEWING_SUBSCRIPTION
                    "inAppPurchaseType": product.inAppPurchaseType.rawValue,
                    "name": product.name,
                    "productId": product.productId,
                    "reviewNote": product.reviewNote,
                ],
                "relationships": [
                    "app": [
                        "data": [
                            "id": appId,
                            "type": "apps"
                        ]
                    ]
                ],
                "type": "inAppPurchases"
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(InAppPurchaseV2CreateRequest.self, from: json)
            let request = APIEndpoint.v2.inAppPurchases.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("创建内购商品失败: \(error.localizedDescription)")
        }
        return nil
    }

    
    /// 修改内购商品
    /// - Parameters:
    ///   - iapId: 内购商品 id
    ///   - product: 内购商品信息
    /// - Returns: 成功时返回对应的商品信息
    func updateInAppPurchases(iapId: String, product: IAPProduct) async -> ASCInAppPurchaseV2? {
        let body = [
            "data": [
                    "attributes": [
                        //"availableInAllTerritories": product.territories.availableInAllTerritories,
                        "familySharable": product.familySharable,
                        "name": product.name,
                        "reviewNote": product.reviewNote,
                    ],
                    "id": iapId,
                    "type": "inAppPurchases"
                ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(InAppPurchaseV2UpdateRequest.self, from: json)
            let request = APIEndpoint.v2.inAppPurchases.id(iapId).patch(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("修改内购商品信息失败: \(error.localizedDescription)")
        }
        return nil
    }

    
    /// 删除内购商品
    /// - Parameters:
    ///   - iapId: 内购商品 id
    /// - Returns: 返回对应的状态码，成功时返回 204
    func deleteInAppPurchases(iapId: String) async -> Int {
        do {
            guard let provider = provider else {
                return 400
            }
            let request = APIEndpoint.v2.inAppPurchases.id(iapId).delete
            try await provider.request(request)
            return 204
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
            return statusCode
        } catch {
            handleError("删除内购商品失败: \(error.localizedDescription)")
        }
        return 400
    }
    
    
    /// 获取内购商品价格档位
    /// - Parameters:
    ///   - iapId: 内购商品 id
    ///   - territory: 国家或地区
    /// - Returns: 成功时返回对应的档位信息
    func fetchPricePoints(iapId: String, territory: [String]?) async -> [ASCIAPPricePoint] {
        let request = APIEndpoint.v2.inAppPurchases.id(iapId).pricePoints
            .get(parameters: .init(
                filterTerritory: territory,
                limit: 200,
                include: [.territory]
            ))
        do {
            guard let provider = provider else {
                return []
            }
            var allApps: [ASCIAPPricePoint] = []
            for try await pagedResult in provider.paged(request) {
                allApps.append(contentsOf: pagedResult.data)
            }
            return allApps
        } catch {
            handleError("获取内购商品价格档位失败: \(error.localizedDescription)")
            return []
        }
    }
    
    
    /// 构建一个价格计划表
    /// - Parameters:
    ///   - scheduleId: 价格计划表 id
    ///   - pricePointId: 价格点 id
    ///   - iapId: 内购商品 id
    /// - Returns: 价格计划表字典
    func fetchInAppPurchasePriceSchedule(scheduleId: String, pricePointId: String, iapId: String) -> [String: Any] {
        [
            "id": scheduleId,
            "type": "inAppPurchasePrices",
            "attributes": [
                "startDate": nil,
                "endDate": nil
            ],
            "relationships": [
                "inAppPurchasePricePoint": [
                    "data": [
                        "id": pricePointId,
                        "type": "inAppPurchasePricePoints"
                    ]
                ],
                "inAppPurchaseV2": [
                    "data": [
                        "id": iapId,
                        "type": "inAppPurchases"
                    ]
                ]
            ]
        ]
    }
    
    
    /// 修改内购商品价格档位
    /// - Parameters:
    ///   - iapId: 内购商品 id
    ///   - baseTerritoryId: 价格档位标识（自定义名字）
    ///   - manualPrices: 价格档位 id
    ///   - included: 内购商品信息
    /// - Returns: 成功时返回对应的档位信息
    func updateInAppPurchasePricePoint(iapId: String, baseTerritoryId: String, manualPrices: [Any], included: [Any]) async -> ASCIAPPriceSchedule? {
        let body: [String : Any] = [
            "data": [
                "type": "inAppPurchasePriceSchedules",
                "relationships": [
                    "inAppPurchase": [
                        "data": [
                            "id": iapId,
                            "type": "inAppPurchases"
                        ]
                    ],
                    "baseTerritory": [
                        "data": [
                            "id": baseTerritoryId,
                            "type": "territories"
                        ]
                    ],
                    "manualPrices": [
                        "data": manualPrices
//                        [
//                            [
//                                "id": priceTierId,
//                                "type": "inAppPurchasePrices"
//                            ]
//                        ]
                    ]
                ]
            ],
            "included": included
//            [
//                [
//                    "id": priceTierId,
//                    "type": "inAppPurchasePrices",
//                    "attributes": [
//                        "startDate": nil,
//                        "endDate": nil
//                    ],
//                    "relationships": [
//                        "inAppPurchasePricePoint": [
//                            "data": [
//                                "id": pricePointId,
//                                "type": "inAppPurchasePricePoints"
//                            ]
//                        ],
//                        "inAppPurchaseV2": [
//                            "data": [
//                                "id": iapId,
//                                "type": "inAppPurchases"
//                            ]
//                        ]
//                    ]
//                ]
//            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(InAppPurchasePriceScheduleCreateRequest.self, from: json)
            let request = APIEndpoint.v1.inAppPurchasePriceSchedules.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("修改内购商品价格档位失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    
    /// 获取内购商品本地化信息
    /// - Parameters:
    ///   - iapId: 内购商品 id
    /// - Returns: 成功时返回对应的所有商品本地化信息
    func fetchInAppPurchasesLocalizations(iapId: String) async -> [ASCIAPLocalization] {
        let request = APIEndpoint.v2.inAppPurchases.id(iapId).inAppPurchaseLocalizations
            .get(parameters: .init(
                limit: 200
            ))
        do {
            guard let provider = provider else {
                return []
            }
            var allApps: [ASCIAPLocalization] = []
            for try await pagedResult in provider.paged(request) {
                allApps.append(contentsOf: pagedResult.data)
            }
            return allApps
        } catch {
            handleError("获取内购商品本地化信息失败: \(error.localizedDescription)")
            return []
        }
    }
    
    
    /// 创建内购商品本地化
    /// - Parameters:
    ///   - iapId: 内购商品 id
    ///   - localization: 本地化信息模型
    /// - Returns: 成功时返回对应的本地化信息
    func createInAppPurchasesLocalization(iapId: String, localization: IAPLocalization) async -> ASCIAPLocalization? {
        let body = [
            "data": [
                "attributes": [
                    "name": localization.name,
                    "description": localization.description,
                    "locale": localization.locale
                ],
                "relationships": [
                    "inAppPurchaseV2": [
                        "data": [
                            "id": iapId,
                            "type": "inAppPurchases"
                        ]
                    ]
                ],
                "type": "inAppPurchaseLocalizations"
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(InAppPurchaseLocalizationCreateRequest.self, from: json)
            let request = APIEndpoint.v1.inAppPurchaseLocalizations.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("创建内购商品本地化信息失败:\(error.localizedDescription)")
        }
        return nil
    }

    
    /// 修改内购商品本地化信息
    /// - Parameters:
    ///   - iapLocaleId: 内购商品本地化语言 id
    ///   - localization: 内购商品本地化模型
    /// - Returns: 成功时返回对应的本地化信息
    func updateInAppPurchasesLocalization(iapLocaleId: String, localization: IAPLocalization) async -> ASCIAPLocalization? {
        let body = [
            "data": [
                "attributes": [
                    "name": localization.name,
                    "description": localization.description,
                ],
                "id": iapLocaleId,
                "type": "inAppPurchaseLocalizations"
            ]
        ]
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(InAppPurchaseLocalizationUpdateRequest.self, from: json)
            let request = APIEndpoint.v1.inAppPurchaseLocalizations.id(iapLocaleId).patch(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("修改内购商品本地化信息失败: \(error.localizedDescription)")
        }
        return nil
    }

    
    /// 删除内购商品本地化
    /// - Parameters:
    ///   - iapLocaleId: 内购商品本地化语言 id
    /// - Returns: 返回对应的状态码，成功时返回 204
    func deleteInAppPurchasesLocalization(iapLocaleId: String) async -> Int {
        do {
            guard let provider = provider else {
                return 400
            }
            let request = APIEndpoint.v1.inAppPurchaseLocalizations.id(iapLocaleId).delete
            try await provider.request(request)
            return 204
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
            return statusCode
        } catch {
            handleError("删除内购商品本地化信息失败:\(error.localizedDescription)")
        }
        return 400
    }
    
    
    /// 获取内购商品的送审截屏
    /// - Parameter iapId: 内购商品 id
    /// - Returns: 返回内购商品的截图信息
    func fetchInAppPurchasesScreenshot(iapId: String) async -> ASCIAPScreenshot? {
        let request = APIEndpoint.v2.inAppPurchases.id(iapId).appStoreReviewScreenshot.get()
        do {
            guard let provider = provider else {
                return nil
            }
            let shot = try await provider.request(request).data
            return shot
        } catch {
            handleError("获取内购商品的送审截图异常: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 创建内购商品的送审截屏
    /// - Parameters:
    ///   - iapId: 内购商品 id
    ///   - fileName: 截图名称
    ///   - fileSize: 截图大小
    /// - Returns: 返回预创建的内购商品的截图信息
    func createInAppPurchasesScreenshot(iapId: String, fileName: String, fileSize: Int) async -> ASCIAPScreenshot? {
        let body = [
            "data": [
                "attributes": [
                    "fileName": fileName,
                    "fileSize": fileSize,
                ],
                "relationships": [
                    "inAppPurchaseV2": [
                        "data": [
                            "id": iapId,
                            "type": "inAppPurchases"
                        ]
                    ]
                ],
                "type": "inAppPurchaseAppStoreReviewScreenshots"
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(InAppPurchaseAppStoreReviewScreenshotCreateRequest.self, from: json)
            let request = APIEndpoint.v1.inAppPurchaseAppStoreReviewScreenshots.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("创建内购商品的送审截图失败:\(error.localizedDescription)")
        }
        return nil
    }
    
    
    /// 确认内购商品的送审截屏
    /// - Parameters:
    ///   - iapShotId: 内购商品截屏 id
    ///   - fileMD5: 内购截屏文件 md5 值
    /// - Returns: 成功时返回对应的截屏模型信息
    func updateInAppPurchasesScreenshot(iapShotId: String, fileMD5: String) async -> ASCIAPScreenshot? {
        let body = [
            "data": [
                "attributes": [
                    "uploaded": true,
                    "sourceFileChecksum": fileMD5,
                ],
                "id": iapShotId,
                "type": "inAppPurchaseAppStoreReviewScreenshots"
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(InAppPurchaseAppStoreReviewScreenshotUpdateRequest.self, from: json)
            let request = APIEndpoint.v1.inAppPurchaseAppStoreReviewScreenshots.id(iapShotId).patch(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("修改内购商品的送审截图失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    /// 删除内购商品的送审截屏
    /// - Parameters:
    ///   - iapShotId: 内购商品截屏 id
    /// - Returns: 成功时返回对应的截屏模型信息
    func deleteInAppPurchasesScreenshot(iapShotId: String) async -> Int {
        do {
            guard let provider = provider else {
                return 400
            }
            let request = APIEndpoint.v1.inAppPurchaseAppStoreReviewScreenshots.id(iapShotId).delete
            try await provider.request(request)
            return 204
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
            return statusCode
        } catch {
            handleError("删除内购商品的送审截图失败:\(error.localizedDescription)")
        }
        return 400
    }
    
    
    /// 修改内购商品的销售范围
    /// - Parameters:
    ///   - iapId: 内购商品 id
    ///   - availableTerritories: 可供销售的国家和地区列表
    ///   - availableInNewTerritories: 是否在将来的所有 App Store 国家或地区中自动提供 App 内购买
    /// - Returns: 成功时返回对应的模型
    func updateInAppPurchasesAvailabilityTerritories(iapId: String, availableTerritories: [Any], availableInNewTerritories: Bool) async -> ASCIAPAvailability? {
        let body = [
            "data": [
                "type": "inAppPurchaseAvailabilities",
                "attributes": [
                    "availableInNewTerritories": availableInNewTerritories
                ],
                "relationships": [
                    "availableTerritories": [
                        "data": availableTerritories
//                        [
//                            [
//                                "type": "territories",
//                                "id": "CHN"
//                            ]
//                        ]
                    ],
                    "inAppPurchase": [
                        "data": [
                            "id": iapId,
                            "type": "inAppPurchases"
                        ]
                    ]
                ]
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(InAppPurchaseAvailabilityCreateRequest.self, from: json)
            let request = APIEndpoint.v1.inAppPurchaseAvailabilities.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("修改内购商品的销售范围失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    
    // MARK: -  续期订阅类商品 API
    
    
    /// 获取所有订阅组
    /// - Parameters:
    ///   - appId: apple id
    /// - Returns: 获取所有订阅组
    func fetchSubscriptionGroups(appId: String) async -> [ASCSubscriptionGroup] {
        let request = APIEndpoint.v1.apps.id(appId).subscriptionGroups
            .get(parameters: .init(
                limit: 200
            ))
        do {
            guard let provider = provider else {
                return []
            }
            var allApps: [ASCSubscriptionGroup] = []
            for try await pagedResult in provider.paged(request) {
                allApps.append(contentsOf: pagedResult.data)
            }
            return allApps
        } catch {
            handleError("获取所有订阅组失败: \(error.localizedDescription)")
            return []
        }
    }
    
    
    /// 创建订阅组
    /// - Parameters:
    ///   - appId: apple id
    ///   - groupName: 订阅组名字
    /// - Returns: 成功时返回订阅组
    func createSubscriptionGroups(appId: String, groupName: String = "VIP") async -> ASCSubscriptionGroup? {
        let body = [
            "data": [
                "attributes": [
                    "referenceName": groupName
                ],
                "relationships": [
                    "app": [
                        "data": [
                            "id": appId,
                            "type": "apps"
                        ]
                    ]
                ],
                "type": "subscriptionGroups"
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(SubscriptionGroupCreateRequest.self, from: json)
            let request = APIEndpoint.v1.subscriptionGroups.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("创建订阅组失败:\(error.localizedDescription)")
        }
        return nil
    }
    
    
    /// 获取所有订阅组的本地化信息
    /// - Parameters:
    ///   - iapGroupId: 订阅组 id
    /// - Returns: 获取所有订阅组
    func fetchSubscriptionGroupLocalizations(iapGroupId: String) async -> [ASCSubscriptionGroupLocale] {
        let request = APIEndpoint.v1.subscriptionGroups.id(iapGroupId).subscriptionGroupLocalizations
            .get(parameters: .init(
                limit: 200
            ))
        do {
            guard let provider = provider else {
                return []
            }
            var allApps: [ASCSubscriptionGroupLocale] = []
            for try await pagedResult in provider.paged(request) {
                allApps.append(contentsOf: pagedResult.data)
            }
            return allApps
        } catch {
            handleError("获取所有订阅组的本地化信息失败: \(error.localizedDescription)")
            return []
        }
    }
    
    
    /// 创建订阅组本地化信息
    /// - Parameters:
    ///   - iapGroupId: 订阅组 id
    ///   - name: 订阅组本地化 id
    ///   - locale: 本地化标识
    ///   - customAppName: 自定义 app 名字
    /// - Returns: 成功时返回订阅组本地化
    func createSubscriptionGroupLocalizations(iapGroupId: String, name: String = "VIP", locale: String = "zh-Hans", customAppName: String?) async -> ASCSubscriptionGroupLocale? {
        let body = [
            "data": [
                "attributes": [
                    "customAppName": customAppName,
                    "name": name,
                    "locale": locale
                ],
                "relationships": [
                    "subscriptionGroup": [
                        "data": [
                            "id": iapGroupId,
                            "type": "subscriptionGroups"
                        ]
                    ]
                ],
                "type": "subscriptionGroupLocalizations"
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(SubscriptionGroupLocalizationCreateRequest.self, from: json)
            let request = APIEndpoint.v1.subscriptionGroupLocalizations.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("创建订阅组本地化信息失败:\(error.localizedDescription)")
        }
        return nil
    }
    
    
    /// 获取订阅组下所有内购商品
    /// - Parameters:
    ///   - appId: apple id
    /// - Returns: 获取所有订阅
    func fetchSubscriptionGroupSubscriptions(iapGroupId: String) async -> [ASCSubscription] {
        let request = APIEndpoint.v1.subscriptionGroups.id(iapGroupId).subscriptions
            .get(parameters: .init(
                limit: 200
            ))
        do {
            guard let provider = provider else {
                return []
            }
            var allApps: [ASCSubscription] = []
            for try await pagedResult in provider.paged(request) {
                allApps.append(contentsOf: pagedResult.data)
            }
            return allApps
        } catch {
            handleError("获取订阅组下所有内购商品失败: \(error.localizedDescription)")
            return []
        }
    }
    
    
    /// 创建订阅商品
    /// - Parameters:
    ///   - iapGroupId: apple id
    ///   - product: 内购商品信息
    /// - Returns: 获取订阅
    func createSubscription(iapGroupId: String, product: IAPProduct) async -> ASCSubscription? {
        let body = [
            "data": [
                "attributes": [
                    "name": product.name,
                    "productId": product.productId,
                    "subscriptionPeriod": product.subscriptions?.subscriptionPeriod ?? "ONE_MONTH",
                    "familySharable": product.familySharable,
                    "reviewNote": product.reviewNote,
                    "groupLevel": product.subscriptions?.groupLevel ?? 1,
                    //"availableInAllTerritories": product.territories.availableInAllTerritories
                ],
                "relationships": [
                    "group": [
                        "data": [
                            "id": iapGroupId,
                            "type": "subscriptionGroups"
                        ]
                    ]
                ],
                "type": "subscriptions"
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(SubscriptionCreateRequest.self, from: json)
            let request = APIEndpoint.v1.subscriptions.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("创建订阅商品失败:\(error.localizedDescription)")
        }
        return nil
    }
    
    
    func updateSubscription(iapId: String, product: IAPProduct) async -> ASCSubscription? {
        let body = [
            "data": [
                "attributes": [
                    "name": product.name,
                    "subscriptionPeriod": product.subscriptions?.subscriptionPeriod ?? "ONE_MONTH",
                    "familySharable": product.familySharable,
                    "reviewNote": product.reviewNote,
                    "groupLevel": product.subscriptions?.groupLevel ?? 1,
                    //"availableInAllTerritories": product.territories.availableInAllTerritories
                ],
                "id": iapId,
                "type": "subscriptions"
            ]
        ]
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(SubscriptionUpdateRequest.self, from: json)
            let request = APIEndpoint.v1.subscriptions.id(iapId).patch(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("修改创建订阅商品失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    
    /// 获取订阅商品本地化信息
    /// - Parameters:
    ///   - iapId: 内购商品 id
    /// - Returns: 成功时返回对应的所有商品本地化信息
    func fetchSubscriptionLocalizations(iapId: String) async -> [ASCSubscriptionLocalization] {
        let request = APIEndpoint.v1.subscriptions.id(iapId).subscriptionLocalizations
            .get(parameters: .init(
                limit: 200
            ))
        do {
            guard let provider = provider else {
                return []
            }
            var allApps: [ASCSubscriptionLocalization] = []
            for try await pagedResult in provider.paged(request) {
                allApps.append(contentsOf: pagedResult.data)
            }
            return allApps
        } catch {
            handleError("获取订阅商品本地化信息失败: \(error.localizedDescription)")
            return []
        }

    }
    
    
    /// 创建订阅商品本地化
    /// - Parameters:
    ///   - iapId: 内购商品 id
    ///   - localization: 本地化信息模型
    /// - Returns: 成功时返回对应的本地化信息
    func createSubscriptionLocalization(iapId: String, localization: IAPLocalization) async -> ASCSubscriptionLocalization? {
        let body = [
            "data": [
                "attributes": [
                    "name": localization.name,
                    "description": localization.description,
                    "locale": localization.locale
                ],
                "relationships": [
                    "subscription": [
                        "data": [
                            "id": iapId,
                            "type": "subscriptions"
                        ]
                    ]
                ],
                "type": "subscriptionLocalizations"
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(SubscriptionLocalizationCreateRequest.self, from: json)
            let request = APIEndpoint.v1.subscriptionLocalizations.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("创建订阅商品本地化信息失败:\(error.localizedDescription)")
        }
        return nil
    }

    
    /// 修改订阅商品本地化信息
    /// - Parameters:
    ///   - iapLocaleId: 内购商品本地化语言 id
    ///   - localization: 内购商品本地化模型
    ///   - product: 内购商品信息
    /// - Returns: 成功时返回对应的本地化信息
    func updateSubscriptionLocalization(iapLocaleId: String, localization: IAPLocalization) async -> ASCSubscriptionLocalization? {
        let body = [
            "data": [
                "attributes": [
                    "name": localization.name,
                    "description": localization.description,
                ],
                "id": iapLocaleId,
                "type": "subscriptionLocalizations"
            ]
        ]
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(SubscriptionLocalizationUpdateRequest.self, from: json)
            let request = APIEndpoint.v1.subscriptionLocalizations.id(iapLocaleId).patch(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("修改订阅商品本地化信息失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    
    /// 获取订阅商品价格档位
    /// - Parameters:
    ///   - iapId: 内购商品 id
    ///   - territory: 国家或地区
    /// - Returns: 成功时返回对应的档位信息
    func fetchSubscriptionPricePoints(iapId: String, territory: [String]?) async -> [ASCSubscriptionPricePoint] {
        let request = APIEndpoint.v1.subscriptions.id(iapId).pricePoints
            .get(parameters: .init(
                filterTerritory: territory,
                limit: 200,
                include: [.territory]
            ))
        do {
            guard let provider = provider else {
                return []
            }
            var allApps: [ASCSubscriptionPricePoint] = []
            for try await pagedResult in provider.paged(request) {
                allApps.append(contentsOf: pagedResult.data)
            }
            return allApps
        } catch {
            handleError("获取订阅商品价格档位失败: \(error.localizedDescription)")
            return []
        }
    }
    
    
    /// 获取订阅商品价格档位的等价价格
    /// - Parameters:
    ///   - pointId: 内购价格档位 id
    ///   - territory: 国家或地区
    /// - Returns: 成功时返回对应的档位信息
    func fetchSubscriptionPricePointsEqualizations(pointId: String, territory: [String]?) async -> [ASCSubscriptionPricePoint] {
        let request = APIEndpoint.v1.subscriptionPricePoints.id(pointId).equalizations
            .get(parameters: .init(
                filterTerritory: territory,
                limit: 200,
                include: [.territory]
            ))
        do {
            guard let provider = provider else {
                return []
            }
            var allApps: [ASCSubscriptionPricePoint] = []
            for try await pagedResult in provider.paged(request) {
                allApps.append(contentsOf: pagedResult.data)
            }
            return allApps
        } catch {
            handleError("获取订阅商品价格档位的等价价格失败: \(error.localizedDescription)")
            return []
        }
    }
    
    
    /// 修改订阅商品价格档位
    /// - Parameters:
    ///   - iapId: 内购商品 id
    ///   - priceTierId: 价格档位标识（自定义名字）
    ///   - pricePointId: 价格档位 id
    /// - Returns: 成功时返回对应的档位信息
    func updateSubscriptionPricePoint(iapId: String, pricePointId: String, preserveCurrentPrice: Bool) async -> ASCSubscriptionPrice? {
        let body: [String : Any] = [
            "data": [
                "type": "subscriptionPrices",
                "attributes": [
                    "startDate": nil,
                    "preserveCurrentPrice": preserveCurrentPrice
                ],
                "relationships": [
                    "subscription": [
                        "data": [
                            "id": iapId,
                            "type": "subscriptions"
                        ]
                    ],
                    "subscriptionPricePoint": [
                        "data": [
                            "id": pricePointId,
                            "type": "subscriptionPricePoints"
                        ]
                    ]
                ]
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(SubscriptionPriceCreateRequest.self, from: json)
            let request = APIEndpoint.v1.subscriptionPrices.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("修改订阅商品价格档位失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    
    /// 获取订阅商品的送审截屏
    func fetchSubscriptionScreenshot(iapId: String) async -> ASCSubscriptionScreenshot? {
        let request = APIEndpoint.v1.subscriptions.id(iapId).appStoreReviewScreenshot.get()
        do {
            guard let provider = provider else {
                return nil
            }
            let shot = try await provider.request(request).data
            return shot
        } catch {
            handleError("获取订阅商品的送审截图异常: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 创建订阅商品的送审截屏
    func createSubscriptionScreenshot(iapId: String, fileName: String, fileSize: Int) async -> ASCSubscriptionScreenshot? {
        let body = [
            "data": [
                "attributes": [
                    "fileName": fileName,
                    "fileSize": fileSize,
                ],
                "relationships": [
                    "subscription": [
                        "data": [
                            "id": iapId,
                            "type": "subscriptions"
                        ]
                    ]
                ],
                "type": "subscriptionAppStoreReviewScreenshots"
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(SubscriptionAppStoreReviewScreenshotCreateRequest.self, from: json)
            let request = APIEndpoint.v1.subscriptionAppStoreReviewScreenshots.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("创建订阅商品的送审截图失败:\(error.localizedDescription)")
        }
        return nil
    }
    
    
    /// 确认订阅商品的送审截屏
    /// - Parameters:
    ///   - iapShotId: 内购商品截屏 id
    ///   - fileMD5: 内购截屏文件 md5 值
    /// - Returns: 成功时返回对应的截屏模型信息
    func updateSubscriptionScreenshot(iapShotId: String, fileMD5: String) async -> ASCSubscriptionScreenshot? {
        let body = [
            "data": [
                "attributes": [
                    "uploaded": true,
                    "sourceFileChecksum": fileMD5,
                ],
                "id": iapShotId,
                "type": "subscriptionAppStoreReviewScreenshots"
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(SubscriptionAppStoreReviewScreenshotUpdateRequest.self, from: json)
            let request = APIEndpoint.v1.subscriptionAppStoreReviewScreenshots.id(iapShotId).patch(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("修改订阅商品的送审截图失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    /// 删除订阅商品的送审截屏
    /// - Parameters:
    ///   - iapShotId: 内购商品截屏 id
    /// - Returns: 成功时返回对应的截屏模型信息
    func deleteSubscriptionScreenshot(iapShotId: String) async -> Int {
        do {
            guard let provider = provider else {
                return 400
            }
            let request = APIEndpoint.v1.subscriptionAppStoreReviewScreenshots.id(iapShotId).delete
            try await provider.request(request)
            return 204
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
            return statusCode
        } catch {
            handleError("删除订阅商品的送审截图失败:\(error.localizedDescription)")
        }
        return 400
    }
    
    
    /// 修改订阅商品的销售范围
    /// - Parameters:
    ///   - iapId: 内购商品 id
    ///   - availableTerritories: 可供销售的国家和地区列表
    ///   - availableInNewTerritories: 是否在将来的所有 App Store 国家或地区中自动提供 App 内购买
    /// - Returns: 成功时返回对应的模型
    func updateSubscriptionAvailabilityTerritories(iapId: String, availableTerritories: [Any], availableInNewTerritories: Bool) async -> ASCSubscriptionAvailability? {
        let body = [
            "data": [
                "type": "subscriptionAvailabilities",
                "attributes": [
                    "availableInNewTerritories": availableInNewTerritories
                ],
                "relationships": [
                    "availableTerritories": [
                        "data": availableTerritories
//                        [
//                            [
//                                "type": "territories",
//                                "id": "CHN"
//                            ]
//                        ]
                    ],
                    "subscription": [
                        "data": [
                            "id": iapId,
                            "type": "subscriptions"
                        ]
                    ]
                ]
            ]
        ]
        
        do {
            guard let provider = provider else {
                return nil
            }
            let json = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            let model = try JSONDecoder().decode(SubscriptionAvailabilityCreateRequest.self, from: json)
            let request = APIEndpoint.v1.subscriptionAvailabilities.post(model)
            let data = try await provider.request(request).data
            return data
        } catch APIProvider.Error.requestFailure(let statusCode, let errorResponse, _) {
            handleRequestFailure(statusCode, errorResponse)
        } catch {
            handleError("修改订阅商品的销售范围失败: \(error.localizedDescription)")
        }
        return nil
    }
}


// MARK: - handle log
extension APASCAPI {
    
    func handleRequestFailure(_ statusCode: Int, _ errorResponse: ErrorResponse?) {
        print("Request failed with statuscode: \(statusCode) and the following errors:")
        errorResponse?.errors?.forEach({ error in
            handleError("Error code: \(error.code), title: \(error.title), detail: \(String(describing: error.detail))")
        })
    }
    
    func handleError(_ msg: String) {
        addMessage(msg)
        print(msg)
    }
    
    func addMessage(_ msg: String) {
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "[MM-dd HH:mm:ss] "
        let currentDateString = dateFormatter.string(from: Date())
        let log = currentDateString + msg
        message.append(log)
        
        // 本地保存
        saveLogs(log: log)
    }
    
    func saveLogs(log: String, retry: Int = 3) {
        do {
            try log.appendLine(to: logPath.createFilePath)
        } catch {
            if retry > 0 {
                self.addMessage("‼️ retry save logs file~ error:\(error)")
                saveLogs(log: log, retry: retry - 1)
            }
        }
    }
}
