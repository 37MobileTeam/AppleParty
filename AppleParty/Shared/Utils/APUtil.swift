//
//  APUtil.swift
//  AppleParty
//
//  Created by HTC on 2022/3/14.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Foundation
import KeychainAccess


public struct Environment {
    public var keychain = APKeychain()
    public var defaults = APDefaults()
}

public var APUtil = Environment()

/// refer:  https://github.com/kishikawakatsumi/KeychainAccess
public struct APKeychain {
    private static let keychain = KeychainAccess.Keychain(service: "com.37iOS.AppleParty")

    public func getString(_ key: String) throws -> String? {
        try APKeychain.keychain.getString(key)
    }

    public func set(_ value: String, key: String) throws {
        try APKeychain.keychain.set(value, key: key)
    }
    
    
    public func getDict(_ key: String) throws -> [String: String]? {
        if let data = try APKeychain.keychain.getData(key) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:String]
                return json
            } catch {
                print("APKeychain getDict something went wrong: \(error.localizedDescription)")
            }
        }
        return nil
    }
    
    public func setDict(_ dict: Dictionary<String, String>, key: String) throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(dict)
        try APKeychain.keychain.set(jsonData, key: key)
    }
    
    public func remove(_ key: String) throws -> Void {
        try APKeychain.keychain.remove(key)
    }
}

public struct APDefaults {
    public var string: (String) -> String? = { UserDefaults.standard.string(forKey: $0) }
    public func string(forKey key: String) -> String? {
        string(key)
    }
    
    public var date: (String) -> Date? = { Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: $0)) }
    public func date(forKey key: String) -> Date? {
        date(key)
    }
    
    public var setDate: (Date?, String) -> Void = { UserDefaults.standard.set($0?.timeIntervalSince1970, forKey: $1) }
    public func setDate(_ value: Date?, forKey key: String) {
        setDate(value, key)
    }
    
    public var set: (Any?, String) -> Void = { UserDefaults.standard.set($0, forKey: $1) }
    public func set(_ value: Any?, forKey key: String) {
        set(value, key)
    }
    
    public var removeObject: (String) -> Void = { UserDefaults.standard.removeObject(forKey: $0) }
    public func removeObject(forKey key: String) {
        removeObject(key)
    }
    
    public var get: (String) -> Any? = { UserDefaults.standard.value(forKey: $0) }
    public func get(forKey key: String) -> Any? {
        get(key)
    }
    
    public var bool: (String) -> Bool? = { UserDefaults.standard.bool(forKey: $0) }
    public func bool(forKey key: String) -> Bool? {
        bool(key)
    }
}
