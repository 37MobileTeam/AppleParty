//
//  UserCenter.swift
//  AppleParty
//
//  Created by HTC on 2022/3/17.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Foundation


struct User {
    var appleid: String
    var password: String
}

struct Provider {
    var name: String
    var providerId: String
    var publicProviderId: String
}

/// 专用密码模型
struct SPassword: Codable {
    var account: String
    var password: String
    var isused: Bool
    
    mutating func model(_ sp: SPassword, _ isused: Bool) -> SPassword {
        SPassword(account: sp.account, password: sp.password, isused: isused)
    }
}

struct SPasswordModel: Codable {
    /// 数据存储
    var list: [SPassword]
}

private let UserCenterKey_HistoryUser_Key = "UserCenterKey_HistoryUser_Key"
private let UserCenterKey_Developer_Key = "UserCenterKey_Developer_Key"
private let UserCenterKey_AutoLogin_Key = "UserCenterKey_AutoLogin_Key"
private let UserCenterKey_AppStoreConnect_Key = "UserCenterKey_AppStoreConnect_Key"

struct UserCenter {
    static var shared = UserCenter()
    /// 账号id
    var accountPrsId = ""
    /// 账号邮箱
    var accountEmail = ""
    /// 账号所有子账号信息
    var accountProviders: [String: Any] = [:]
    /// 账号登陆态是否有效
    var isAuthorized = false
    
    
    // MARK: - 历史登录用户
    lazy var historyUser: [User] = {
        if let value = try? APUtil.keychain.getString(UserCenterKey_HistoryUser_Key) {
            let array = value.components(separatedBy: "|")
            var result = [User]()
            for temp in array {
                result.append(User(appleid: temp.components(separatedBy: "_").first ?? "", password: temp.components(separatedBy: "_").last ?? ""))
            }
            return result
        }
        return []
    }()
    
    // MARK: - 登录用户
    var loginedUser: User {
        mutating get {
            return historyUser.first ?? User(appleid: "", password: "")
        }
        set {
            historyUser = historyUser.filter{ $0.appleid != newValue.appleid }
            historyUser.insert(newValue, at: 0)
            let value = historyUser.map { $0.appleid + "_" + $0.password }.joined(separator: "|")
            try? APUtil.keychain.set(value, key: UserCenterKey_HistoryUser_Key)
        }
    }
    
    
    // MARK: - 开发者信息
    /// 开发者 id
    var developerId = ""
    /// 新的开发者id
    var publicDeveloperId = ""
    /// 开发者名字
    var developerName = ""
    /// 开发者团队 id
    var developerTeamId = ""
    /// 苹果账号专用密码
    var currentSPassword: SPassword? {
        get {
            let accounts = self.secondaryPasswordList
            let models = accounts.filter({ $0.isused == true })
            return models.first
        }
    }
    // 所有的专用密码
    var secondaryPasswordList: [SPassword] {
        set {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(SPasswordModel(list: newValue)) {
                try? APUtil.keychain.set(data, key: UserCenterKey_Developer_Key)
            }
        }
        get {
            if let listData = try? APUtil.keychain.getData(UserCenterKey_Developer_Key),
               let model = try? JSONDecoder().decode(SPasswordModel.self, from: listData) {
                return model.list
            } else {
                return []
            }
        }
    }
    
    // MARK: - 自动登录态
    var isFirstTime = true
    var isAutoLogin: Bool {
        get {
            return APUtil.defaults.bool(forKey: UserCenterKey_AutoLogin_Key) ?? false
        }
        set {
            APUtil.defaults.set(newValue, forKey: UserCenterKey_AutoLogin_Key)
        }
    }
}
