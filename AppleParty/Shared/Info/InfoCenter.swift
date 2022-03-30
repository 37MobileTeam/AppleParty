//
//  InfoCenter.swift
//  AppleParty
//
//  Created by HTC on 2022/3/17.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Foundation


let InfoCenterKey_Scnt_Key = "InfoCenterKey_Scnt_Key"
let InfoCenterKey_SessionId_Key = "InfoCenterKey_SessionId_Key"
let InfoCenterKey_Cookies_Key = "InfoCenterKey_Cookies_Key"
let InfoCenterKey_TrusDevice_Key = "InfoCenterKey_TrusDevice_Key"

struct InfoCenter {
    static var shared = InfoCenter()
    
    var scnt: String {
        get {
            return (try? APUtil.keychain.getString(InfoCenterKey_Scnt_Key)) ?? ""
        }
        set {
            try? APUtil.keychain.set(newValue, key: InfoCenterKey_Scnt_Key)
        }
    }

    var sessionId: String {
        get {
            return (try? APUtil.keychain.getString(InfoCenterKey_SessionId_Key)) ?? ""
        }
        set {
            try? APUtil.keychain.set(newValue, key: InfoCenterKey_SessionId_Key)
        }
    }

    var cookies: [HTTPCookie] {
        get {
            let cookies = NSKeyedUnarchiver.unarchiveObject(with: APUtil.defaults.get(forKey: InfoCenterKey_Cookies_Key) as? Data ?? Data())
            return cookies as? [HTTPCookie] ?? []
        }
        set {
            let cookieData = NSKeyedArchiver.archivedData(withRootObject: newValue)
            APUtil.defaults.set(cookieData, forKey: InfoCenterKey_Cookies_Key)
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
