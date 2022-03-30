//
//  APAppListModel.swift
//  AppleParty
//
//  Created by HTC on 2022/3/17.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Foundation

// MARK: - 游戏列表
struct AppList {
    var games: [App]
    
    init(body: [String: Any]) {
        games = [App]()
        let data = dictionary(body["data"])
        let softwares = dictionaryArray(data["softwares"])
        for software in softwares {
            var game = App()
            game.adamId = string(from: software["adamId"])
            game.appName = string(from: software["appName"])
            game.platforms = string(from: software["platforms"])
            game.largeIconUrl = string(from: software["largeIconUrl"])
            game.largeIconType = string(from: software["largeIconType"])
            game.iconPlatform = string(from: software["iconPlatform"])
            games.append(game)
        }
        games = games.sorted(by: { (g1, g2) -> Bool in
            g1.appName < g2.appName
        })
    }
}

struct App {
    var adamId: String = ""
    var appName: String = ""
    var platforms: String = ""
    var largeIconUrl: String = ""
    var largeIconType: String = ""
    var iconPlatform: String = ""
}

struct AppInfo {
    var name: String = ""
    var bundleId: String = ""
    var bundleIdReferenceName: String = ""
    var distributionType: String = ""
    var educationDiscountType: String = ""
    var sku: String = ""
    var primaryLocale: String = ""
    
    init(body: [String: Any]) {
        let data = dictionary(body["data"])
        let attributes = dictionary(data["attributes"])
        name = string(from: attributes["name"])
        bundleId = string(from: attributes["bundleId"])
        bundleIdReferenceName = string(from: attributes["bundleIdReferenceName"])
        distributionType = string(from: attributes["distributionType"])
        educationDiscountType = string(from: attributes["educationDiscountType"])
        sku = string(from: attributes["sku"])
        primaryLocale = string(from: attributes["primaryLocale"])
    }
}
