//
//  APClient.swift
//  AppleParty
//
//  Created by HTC on 2022/3/17.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Foundation
import Alamofire


let baseHeaders: HTTPHeaders = [
    "Content-Type": "application/json",
    "X-Apple-Widget-Key": "e0b80c3bf78523bfe80974d320935bfa30add02e1bff88ec2166c6bd5a706c42", //目前固定值
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15",
    "Accept": "application/json, text/plain, */*;q=0.8",
    "Accept-Language": "zh-CN,zh;q=0.9",
    "Referer": "https://appstoreconnect.apple.com",
    "X-Requested-By": "dev.apple.com", //分析数据下载必备
    "fetch-csrf-token": "1", // 销售量数据下载必备
    "uicomponentname": "measureDisplay"
]


struct APClientSession {
    static var shared = APClientSession()
    let session: Session
    let config: URLSessionConfiguration
    let policy = RetryPolicy()
    let getEncoding = URLEncoding.httpBody
    let postEncoding = JSONEncoding.default
    
    init() {
        config = URLSessionConfiguration.af.default
        var headers: HTTPHeaders = baseHeaders
        if InfoCenter.shared.scnt.isNotEmpty, InfoCenter.shared.sessionId.isNotEmpty {
            headers.add(name: "scnt", value: InfoCenter.shared.scnt)
            headers.add(name: "X-Apple-ID-Session-Id", value: InfoCenter.shared.sessionId)
        }
        config.headers = headers
        
        for cookie in InfoCenter.shared.cookies {
            config.httpCookieStorage?.setCookie(cookie)
        }
        
        session = Session(configuration: config)
    }
}

enum AppListStatus {
    case all
    case available
    case filter(_ query: String?)
}

enum APClient {
    // 初始化登录请求
    case signIn(account: String, password: String)
    // 获取登录itCtx cookie
    case signInSession
    // 用于检查session是否过期
    case validateSession
    // 查询/发送手机验证码
    case verifySecurityPhone(mode: String, phoneid: Int)
    // 手机验证码验证
    case submitSecurityCode(code: SecurityCode)
    // 信任登陆设备
    case trusDevice(isTrus: Bool)
    // 开发者新闻
    case providerNews
    // 账号合同消息
    case providerContractMessage
    // 应用列表
    case appList(status: AppListStatus)
    // 应用版本
    case appVersion(appid: String)
    // 内购列表-新
    case inAppPurchase(appid: String, type: IAPSearchType)
    // 内购详情-新
    case inAppPurchaseDetail(iapid: String)
    // 内购商品的价格档位
    case inAppPurchasePrices(iapid: String)
    // 内购列表-旧
    case iaps(appid: String)
    // 开发者信息
    case ascProvider
    case ascProviders
    // 切换账号
    case switchProvider(publicProviderId: String)
    // 游戏详细信息
    case appInfo(appid: String)
    // app分析数据
    case appAnalytics(appid: String, measures: String, frequency: String, startTime: String, endTime: String, filters: [String:Any]? = nil, group: String? = nil, csv: Bool = true)
    case initCSRF
    // app销售趋势
    case appSalestrends(appid: String, measures: String, frequency: String, startTime: String, endTime: String, measuresKeys: [[String:Any]], groupKey: String? = nil, optionKeys: [[String:Any]]? = nil, vcubes: Int)
    // 根据providerid查询供应商编号
    case sapVendorNumbers(providerId: String)
    // 下载汇总财务报表
    case summaryFinancialReport(providerId: String, vendorNumber: String, year: String, month: String)
    // 获取付款汇总信息
    case paymentConsolidation(providerId: String, vendorNumber: String, year: String, month: String)
    // 生成财务详细报告
    case generateFinancialReport(providerId: String, vendorNumber: String, year: String, month: String, regionCurrencyIds: [String])
    // 查询财务报告生成状态
    case generateFinancialReportStatus(providerId: String, vendorNumber: String, uuid: String)
    // 下载详细财务报告
    case detailFinancialReport(url: String)
    // 用户详情
    case userDetail
    // 银行列表
    case bankList(contentProviderPublicId: String)
    // 银行账号
    case bankAccountNumber(contentProviderPublicId: String, bankAccountInfoId: String)
    
    
    enum SecurityCode {
        case device(code: String)
        case sms(code: String, phoneNumberId: Int, mode: String)
        
        var urlPathComponent: String {
            switch self {
            case .device: return "trusteddevice"
            case .sms: return "phone"
            }
        }
    }
    
    enum IAPSearchType {
        case all
        case submit
    }
}

extension APClient {
    func sessionMethod() -> HTTPMethod {
        switch self {
        case .signIn, .submitSecurityCode, .appAnalytics, .appSalestrends, .initCSRF, .switchProvider:
            return .post
        case .signInSession, .inAppPurchase, .iaps, .ascProvider, .ascProviders, .appInfo, .trusDevice, .providerNews, .providerContractMessage, .validateSession, .sapVendorNumbers, .summaryFinancialReport, .paymentConsolidation, .generateFinancialReport, .generateFinancialReportStatus, .detailFinancialReport, .appVersion, .bankList, .bankAccountNumber, .userDetail, .appList, .inAppPurchasePrices, .inAppPurchaseDetail:
            return .get
        case .verifySecurityPhone:
            return .put
        }
    }
    
    func sessionEncode() -> ParameterEncoding {
        if sessionMethod() == .get {
            return APClientSession.shared.getEncoding
        } else {
            return APClientSession.shared.postEncoding
        }
    }
    
    func sessionHeaders(_ headers: HTTPHeaders) -> HTTPHeaders {
        var newHeaders = headers
        switch self {
        case .initCSRF:
            newHeaders.update(name: "fetch-csrf-token", value: "1")
        case .switchProvider:
            newHeaders.update(name: "X-Requested-With", value: "olympus-ui")
        default:
            break
        }
        return newHeaders
    }
    
    func getUrl() -> String {
        switch self {
        case .signIn:
            return "https://idmsa.apple.com/appleauth/auth/signin?isRememberMeEnabled=true"
        case .signInSession:
            return "https://appstoreconnect.apple.com/olympus/v1/session"
        case .validateSession:
            return "https://appstoreconnect.apple.com/olympus/v1/check"
        case .verifySecurityPhone:
            return "https://idmsa.apple.com/appleauth/auth/verify/phone"
        case let .submitSecurityCode(code):
            return "https://idmsa.apple.com/appleauth/auth/verify/\(code.urlPathComponent)/securitycode"
        case let .appList(status):
            switch status {
            case .all:
                return "https://appstoreconnect.apple.com/iris/v1/apps?limit=999"
            case .available:
                return "https://appstoreconnect.apple.com/iris/v1/apps?include=reviewSubmissions&limit=999&filter[removed]=false&filter[appStoreVersions.appStoreState]=READY_FOR_SALE"
            case .filter(query: let query):
                let filter = query ?? "limit=999&include=appStoreVersions&limit[appStoreVersions]=1"
                return "https://appstoreconnect.apple.com/iris/v1/apps?\(filter)"
            }
        case let .appVersion(appid):
            return "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/"+appid+"/overview"
        case let .inAppPurchase(appid, type):
            var filter = ""
            if type == .all {
                filter = "filter[canBeSubmitted]=true&limit=500&sort=-referenceName&include=inAppPurchaseReviewSubmission&"
            } else if type == .submit {
                filter = "fields[inAppPurchase]=referenceName,productId,inAppPurchaseType&filter[canBeSubmitted]=true&limit=500&sort=-referenceName&exists[inAppPurchaseReviewSubmission]=true&"
            }
            return "https://appstoreconnect.apple.com/iris/v1/apps/"+appid+"/inAppPurchase?"+filter
        case let .iaps(appid):
            return "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/apps/"+appid+"/iaps"
        case let .inAppPurchaseDetail(iapid):
            return "https://appstoreconnect.apple.com/iris/v2/inAppPurchases/\(iapid)?include=inAppPurchaseLocalizations,content,promotedPurchase,appStoreReviewScreenshot,inAppPurchaseTaxCategoryInfo&limit[inAppPurchaseLocalizations]=200"
        case let .inAppPurchasePrices(iapid):
            return "https://appstoreconnect.apple.com/iris/v2/inAppPurchases/\(iapid)/prices?include=inAppPurchasePricePoint&filter[territory]=USA"
        case .ascProvider:
            return "https://appstoreconnect.apple.com/olympus/v1/actors?include=provider"
        case .ascProviders:
            return "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/users/itc"
        case .switchProvider:
            return "https://appstoreconnect.apple.com/olympus/v1/providerSwitchRequests"
        case let .appInfo(appid):
            return "https://appstoreconnect.apple.com/iris/v1/apps/"+appid+"?include=appStoreVersions&limit[appStoreVersions]=6"
        case .appAnalytics(_, _, _, _, _, _, _, csv: let csv):
            if csv {
                return "https://appstoreconnect.apple.com/analytics/api/v1/data/time-series-csv"
            }
            return "https://appstoreconnect.apple.com/analytics/api/v1/data/time-series"
        case .appSalestrends(param: let param):
            return "https://appstoreconnect.apple.com/trends/gsf/salesTrendsApp/businessareas/InternetServices/subjectareas/iTunes/vcubes/\(param.vcubes)/timeseries"
        case .initCSRF:
            return "https://appstoreconnect.apple.com/trends/gsf/owasp/csrf-guard.js"
        case let .trusDevice(isTrus):
            guard isTrus else {
                return "https://idmsa.apple.com/appleauth/auth/2sv/donttrust"
            }
            return "https://idmsa.apple.com/appleauth/auth/2sv/trust"
        case .providerNews:
            return "https://appstoreconnect.apple.com/olympus/v1/providerNews"
        case .providerContractMessage:
            return "https://appstoreconnect.apple.com/olympus/v1/contractMessages"
        case .sapVendorNumbers(providerId: let providerId):
            return "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/paymentConsolidation/providers/\(providerId)/sapVendorNumbers"
        case .summaryFinancialReport(providerId: let providerId, vendorNumber: let vendorNumber, year: let year, month: let month):
            return "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/wa/downloadFinancialReportPageCSV?contentProviderId=\(providerId)&sapVendorNumber=\(vendorNumber)&year=\(year)&month=\(month)"
        case .paymentConsolidation(providerId: let providerId, vendorNumber: let vendorNumber, year: let year, month: let month):
            return "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/paymentConsolidation/providers/\(providerId)/sapVendorNumbers/\(vendorNumber)?year=\(year)&month=\(month)"
        case .generateFinancialReport(providerId: let providerId, vendorNumber: let vendorNumber, year: let year, month: let month, regionCurrencyIds: let regionCurrencyIds):
            return "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/paymentConsolidation/providers/\(providerId)/sapVendorNumbers/\(vendorNumber)/reports?year=\(year)&month=\(month)&regionCurrencyIds=\(regionCurrencyIds.joined(separator: ","))&reportTypes=APP_STORE_REPORT&isDetailedConsolidatedReq=true"
        case .generateFinancialReportStatus(providerId: let providerId, vendorNumber: let vendorNumber, uuid: let uuid):
            return "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/paymentConsolidation/providers/\(providerId)/sapVendorNumbers/\(vendorNumber)/reports/\(uuid)/status"
        case .detailFinancialReport(url: let url):
            return "https://appstoreconnect.apple.com\(url)"
        case .userDetail:
            return "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/user/detail"
        case .bankList(contentProviderPublicId: let id):
            return "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/contentProviders/\(id)/bankAccounts?meta=constraints"
        case .bankAccountNumber(contentProviderPublicId: let contentProviderPublicId, bankAccountInfoId: let bankAccountInfoId):
            return "https://appstoreconnect.apple.com/WebObjects/iTunesConnect.woa/ra/contentProviders/\(contentProviderPublicId)/decryptedBankAccounts/\(bankAccountInfoId)"
        }
    }
    
    func getParam() -> [String: Any] {
        var payload: [String: Any] = [:]
        switch self {
        case let .signIn(account, password):
            payload["accountName"] = account
            payload["password"] = password
            payload["rememberMe"] = true
        case let .verifySecurityPhone(mode, phoneid):
            payload["phoneNumber"] = ["id": phoneid]
            payload["mode"] = mode //"sms" "voice"
        case let .submitSecurityCode(code):
            switch code {
            case .device(let code):
                payload["securityCode"] = ["code": code]
            case .sms(let code, let phoneNumberId, let mode):
                payload["securityCode"] = ["code": code]
                payload["phoneNumber"] = ["id": phoneNumberId]
                payload["mode"] = mode //"sms" "voice"
            }
        case let .switchProvider(publicProviderId):
            payload["data"] = [
                "type": "providerSwitchRequests",
                "relationships": [
                    "provider": [
                        "data": [
                            "id": publicProviderId,
                            "type": "providers"
                        ]
                    ]
                ]
            ]
        case let .appAnalytics(appid, measures, frequency, startTime, endTime, filters, group, _):
            payload["adamId"] = [appid]
            payload["measures"] = [measures]
            payload["frequency"] = frequency
            payload["startTime"] = startTime
            payload["endTime"] = endTime
            payload["group"] = group
            if let filter = filters {
                payload["dimensionFilters"] = [filter]
            }
        case let .appSalestrends(appid, measures, frequency, startTime, endTime, measuresKeys, groupKey, optionKeys, _):
            payload["componentName"] = measures
            payload["group"] = []
            if let group = groupKey {
                payload["group"] = [ group ]
            }
            payload["measures"] = measuresKeys
            payload["cubeName"] = "sales"
            payload["cubeApiType"] = "TIMESERIES"
            payload["interval"] = [ "key": frequency, "startDate": startTime, "endDate": endTime]
            payload["filters"] = [ [ "dimensionKey": groupKey ?? "gross_adam_id_piano", "optionKeys": [ appid ] ] ]
            if let options = optionKeys {
                var filter = payload["filters"] as! Array<[String: Any]>
                filter.append(contentsOf: options)
                payload["filters"] = filter
            }
        default:
            break
        }
        return payload
    }
}

extension APClient {
    typealias CompletionHandler = (_ result: [String: Any], _ response: HTTPURLResponse?, _ error: NSError?) -> Void
    
    func request(showLoading: Bool = false, inView: NSView = currentView() , retry: Int = 3, completionHandler: CompletionHandler?) {
        
        if showLoading {
            APHUD.showLoading(inView)
        }
        
        APClientSession.shared.session.request(getUrl(),
                                             method: sessionMethod(),
                                             parameters: sessionMethod() == .get ? nil : getParam(),
                                             encoding: sessionEncode(),
                                             headers: sessionHeaders(APClientSession.shared.config.headers),
                                             interceptor: APClientSession.shared.policy).response { (dataResponse) in
            if showLoading {
                APHUD.hideLoading()
            }
            
            var json = [String: Any]()
            if let jsonObject = try? JSONSerialization.jsonObject(with: dataResponse.data ?? Data()), let dict = jsonObject as? [String: Any] {
                json = dict
            } else {
                if let jsonObject = try? JSONSerialization.jsonObject(with: dataResponse.data ?? Data()), let array = jsonObject as? [Any] {
                    json = ["data": array]
                } else {
                    let dataStr = String(decoding: dataResponse.data ?? Data(), as: UTF8.self)
                    APLogs.shared.add("返回数据非json格式：\(dataStr)", printlog: true)
                    // 非 json 格式内容，但接口需要这个内容
                    switch self {
                    case .initCSRF, .validateSession:
                        json = ["data": dataStr]
                    default:
                        break
                    }
                }
            }

            APLogs.shared.add("👉 [Response] \(string(from: dataResponse.response?.statusCode)) \(getUrl())", printlog: true)
            let isRetry = networkOperation(json: json, response: dataResponse.response)
            if isRetry && retry > 0 {
                APLogs.shared.add("‼️ Retry request: \(getUrl())", printlog: true)
                request(showLoading: showLoading, retry: retry - 1, completionHandler: completionHandler)
                return
            }
            
            // status code 统一处理
            if let code = dataResponse.response?.statusCode {
                switch code {
                case 200...299:
                    completionHandler?(json, dataResponse.response, nil)
                case 401:
                    if case .switchProvider = self, retry > 0 {
                        APLogs.shared.add("‼️ Retry request: \(getUrl())", printlog: true)
                        request(showLoading: showLoading, retry: retry - 1, completionHandler: completionHandler)
                        return
                    }
                    
                    // 登录session已过期
                    var errors = dictionaryArray(json["errors"])
                    var msg = string(from: errors.first?["title"])
                    if errors.count == 0 {
                        errors = dictionaryArray(json["serviceErrors"])
                        msg = string(from: errors.first?["message"])
                    }
                    completionHandler?(json, dataResponse.response, NSError.APClientError(.notAuthorized, msg))
                case 403:
                    completionHandler?(json, dataResponse.response, NSError.APClientError(.accountLocked))
                case 409:
                    completionHandler?(json, dataResponse.response, NSError.APClientError(.twoStepOrFactor))
                case 412:
                    completionHandler?(json, dataResponse.response, NSError.APClientError(.privacyAcknowledgementRequired))
                case 500...599:
                    if retry > 0 {
                        request(showLoading: showLoading, retry: retry - 1, completionHandler: completionHandler)
                        return
                    }
                    completionHandler?(json, dataResponse.response, NSError.APClientError(.serviceBadStatusCode, dataResponse.error?.localizedDescription ?? ""))
                default:
                    completionHandler?(json, dataResponse.response, NSError.APClientError(.failure, dataResponse.error?.localizedDescription ?? ""))
                }
            } else {
                completionHandler?(json, dataResponse.response, NSError.APClientError(.unknown, dataResponse.error?.localizedDescription ?? ""))
            }
        }
    }
    
    func download(filePath: URL, retry: Int = 3, completionHandler: CompletionHandler?)  {
        
        let destination: DownloadRequest.Destination = { _,_ in
            return (filePath, [.createIntermediateDirectories, .removePreviousFile])
        }
        
        APClientSession.shared.session.download(getUrl(),headers: APClientSession.shared.config.headers,
                                              interceptor: nil, requestModifier: nil, to: destination).response { dataResponse in
                                                switch dataResponse.result {
                                                case .success(_):
                                                    completionHandler?(["filePath":filePath.path], dataResponse.response, nil)
                                                case let .failure(error):
                                                    completionHandler?([:], dataResponse.response, error as NSError)
                                                }
                                            }
    }
}



extension APClient {
    func networkOperation(json: [String: Any], response: HTTPURLResponse?, config: URLSessionConfiguration = APClientSession.shared.config) -> Bool {
        switch self {
        case .signIn:
            let status_code = int(from: response?.statusCode)
            switch status_code {
            case 200, 409:
                if let header = response?.headers {
                    APClientSession.shared.config.headers.update(name: "scnt", value: string(from: header["scnt"]))
                    APClientSession.shared.config.headers.update(name: "X-Apple-ID-Session-Id", value: string(from: header["X-Apple-ID-Session-Id"]))
                    InfoCenter.shared.scnt = string(from: header["scnt"])
                    InfoCenter.shared.sessionId = string(from: header["X-Apple-ID-Session-Id"])
                }
            default: break
            }
        case .submitSecurityCode, .switchProvider:
            InfoCenter.shared.cookies = APClientSession.shared.config.httpCookieStorage?.cookies ?? []
            if case .switchProvider = self {
                config.headers.update(name: "X-Requested-With", value: "olympus-ui")
            }
        case .signInSession:
            if json.isNotEmpty {
                InfoCenter.shared.cookies = APClientSession.shared.config.httpCookieStorage?.cookies ?? []
                UserCenter.shared.accountProviders = json
                UserCenter.shared.accountPrsId = string(from: dictionary(json["user"])["prsId"])
                UserCenter.shared.accountEmail = string(from: dictionary(json["user"])["emailAddress"])
                UserCenter.shared.developerId = string(from: dictionary(json["provider"])["providerId"])
                UserCenter.shared.publicDeveloperId = string(from: dictionary(json["provider"])["publicProviderId"])
                UserCenter.shared.developerName = string(from: dictionary(json["provider"])["name"])
            }
        case .appList:
            if response?.statusCode != 200 {
                return true
            }
        case .ascProvider:
            let includeds = dictionaryArray(json["included"])
            for included in includeds {
                let internalId = string(from: dictionary(included["attributes"])["internalId"])
                if internalId == UserCenter.shared.developerId {
                    UserCenter.shared.developerTeamId = string(from: dictionary(included["attributes"])["developerTeamId"])
                    break
                }
            }
        case .validateSession:
            // 如果有 code ==200, 且 data: Unauthenticated 开头内容，则表示 sessio 过期，重试
            let status_code = int(from: response?.statusCode)
            if status_code != 401 {
                sleep(1)
                return true
            }
        case .initCSRF:
            if let data = json["data"] as? String, data.count > 0, data.hasPrefix("CSRF") {
                let index = data.index(data.startIndex, offsetBy: 5)
                let csrf = String(data.suffix(from: index))
                config.headers.update(name: "x-requested-with", value: "OWASP CSRFGuard Project")
                config.headers.update(name: "csrf", value: csrf)
            }
        case .appSalestrends:
            guard (json["result"] as? [[String: [Any]]]) != nil else {
                return true
            }
        default:
            break
        }
        
        return false
    }
}



// MARK: - 请求错误码
public enum APClientErrorCode: Int {
    case failure = 400
    case notAuthorized = 401
    case accountLocked = 403
    case twoStepOrFactor = 409
    case privacyAcknowledgementRequired = 412
    case serviceBadStatusCode = 500
    case notDeveloperAppleId = 9998
    case unknown = 9999
    
    public var errorDescription: String {
        switch self {
        case .failure:
            return "请求失败"
        case .notAuthorized:
            return "登陆过期，请重新登陆账号。"
        case .accountLocked:
            return "账号被禁用，详细请登陆 https://appstoreconnect.apple.com 了解更多。"
        case .twoStepOrFactor:
            return "需要进行双重认证。"
        case .privacyAcknowledgementRequired:
            return "账号需要同意新协议，详细请登陆 https://appstoreconnect.apple.com 了解更多。"
        case .notDeveloperAppleId:
            return "账号未注册 Apple 开发者！"
        case .unknown:
            return "未知错误"
        case .serviceBadStatusCode:
            return "服务端处理异常，请重试~"
        }
    }
}

extension NSError {
    static func APClientError(_ code: APClientErrorCode, _ message: String = "") -> NSError {
        return NSError(domain: "com.AppleParty.error", code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: message.count > 0 ? message : code.errorDescription])
    }
}
