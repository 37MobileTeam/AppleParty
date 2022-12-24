//
//  InfoCenter.swift
//  AppleParty
//
//  Created by HTC on 2022/3/17.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Foundation

let InfoCenterKey_Session_Key = "InfoCenterKey_Session_Key"
let InfoCenterKey_TrusDevice_Key = "InfoCenterKey_TrusDevice_Key"

/// AppStoreConnect 密钥模型
struct AppStoreConnectKey: Codable {
    var aliasName: String
    var issuerID: String
    var privateKeyID: String
    var privateKey: String
    var isused: Bool
    
    mutating func model(_ asck: AppStoreConnectKey, _ isused: Bool) -> AppStoreConnectKey {
        AppStoreConnectKey(aliasName: asck.aliasName, issuerID: asck.issuerID, privateKeyID: asck.privateKeyID, privateKey: asck.privateKey, isused: isused)
    }
}


/// 信息模型
struct AppleInfoSession: Codable {
    var scnt: String
    var sessionId: String
    var cookies: Data
    var ascKeys: [AppStoreConnectKey]
}


struct InfoCenter {
    static var shared = InfoCenter()
    
    var session: AppleInfoSession {
        set {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(newValue) {
            #if DEBUG
                UserDefaults.standard.set(data, forKey: InfoCenterKey_Session_Key)
            #else
                try? APUtil.keychain.set(data, key: InfoCenterKey_Session_Key)
            #endif
            }
        }
        get {
            var data: Data?
        #if DEBUG
            data = UserDefaults.standard.data(forKey: InfoCenterKey_Session_Key)
        #else
            data = try? APUtil.keychain.getData(InfoCenterKey_Session_Key)
        #endif
            if let data = data, let model = try? JSONDecoder().decode(AppleInfoSession.self, from: data) {
                return model
            } else {
                return AppleInfoSession(scnt: "", sessionId: "", cookies: Data(), ascKeys: [])
            }
        }
    }
    
    var scnt: String {
        get {
            session.scnt
        }
        set {
            session = AppleInfoSession(scnt: newValue, sessionId: session.sessionId, cookies: session.cookies, ascKeys: session.ascKeys)
        }
    }

    var sessionId: String {
        get {
            session.sessionId
        }
        set {
            session = AppleInfoSession(scnt: session.scnt, sessionId: newValue, cookies: session.cookies, ascKeys: session.ascKeys)
        }
    }

    var cookies: [HTTPCookie] {
        get {
            let data = session.cookies
            // NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, HTTPCookie.self], from: data)
            // adopt NSSecureCoding. Class 'NSHTTPCookie' does not adopt it
            let cookies = try? NSKeyedUnarchiver.unarchiveObject(with: data)
            return cookies as? [HTTPCookie] ?? []
        }
        set {
            let cookieData = (try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)) ?? Data()
            session = AppleInfoSession(scnt: session.scnt, sessionId: session.sessionId, cookies: cookieData, ascKeys: session.ascKeys)
        }
    }
    
    var ascKeys: [AppStoreConnectKey] {
        get {
            session.ascKeys
        }
        set {
            session = AppleInfoSession(scnt: session.scnt, sessionId: session.sessionId, cookies: session.cookies, ascKeys: newValue)
        }
    }
    
    var currentASCKey: AppStoreConnectKey? {
        get {
            let accounts = self.ascKeys
            let models = accounts.filter({ $0.isused == true })
            return models.first
        }
    }

    var trusDevice: Bool {
        get {
            if let trus = APUtil.defaults.bool(forKey: InfoCenterKey_TrusDevice_Key) {
                return trus
            }
            return true //默认为信任设备
        }
        set {
            APUtil.defaults.set(newValue, forKey: InfoCenterKey_TrusDevice_Key)
        }
    }
}
