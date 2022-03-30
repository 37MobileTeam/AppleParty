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
}

private let UserCenterKey_HistoryUser_Key = "UserCenterKey_HistoryUser_Key"
private let UserCenterKey_Developer_Key = "UserCenterKey_Developer_Key"
private let UserCenterKey_AutoLogin_Key = "UserCenterKey_AutoLogin_Key"
private let UserCenterKey_LastGameID_Key = "UserCenterKey_LastGameID_Key"

struct UserCenter {
    static var shared = UserCenter()
    /// 账号id
    var accountPrsId = ""
    /// 账号邮箱
    var accountEmail = ""
    /// 账号所有子账号信息
    var accountProviders: [String: Any] = [:]
    /// 账号所有 app
    var accountApps: [String: Any] = [:]
    /// 账号登陆态是否有效
    var isAuthorized = false
    
    
    // MARK: - 历史登录用户
    var historyUser: [User] = {
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
        get {
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
    /// 开发者名字
    var developerName = ""
    /// 开发者团队 id
    var developerTeamId = ""
    /// 苹果账号特殊密码
    var developerKey: String {
        get {
            return (try? APUtil.keychain.getString(accountPrsId + "_" + UserCenterKey_Developer_Key)) ?? ""
        }
        set {
            try? APUtil.keychain.set(newValue, key: accountPrsId + "_" + UserCenterKey_Developer_Key)
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
