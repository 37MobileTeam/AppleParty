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
          let included = dictionaryArray(body["included"])
          let apps = dictionaryArray(body["data"])
          for software in apps {
               var game = App()
               let attributes = dictionary(software["attributes"])
               game.appId = string(from: software["id"])
               game.appName = string(from: attributes["name"])
               game.platforms = string(from: attributes["distributionType"])
               game.bundleId = string(from: attributes["bundleId"])
               game.sku = string(from: attributes["sku"])
               game.primaryLocale = string(from: attributes["primaryLocale"])
               // icon 处理
               let appVersion = dictionaryArray( dictionary( dictionary(software["relationships"])["appStoreVersions"])["data"]).first
               if let version = appVersion {
                    let vid = string(from: version["id"])
                    for info in included {
                         let iid = string(from: info["id"])
                         if vid == iid, vid.count > 0 {
                              let info_att = dictionary(info["attributes"])
                              let storeIcon = dictionary(info_att["storeIcon"])
                              let templateUrl = string(from: storeIcon["templateUrl"])
                              if templateUrl.count > 0 {
                                   game.iconUrl = templateUrl.replacingOccurrences(of: "{w}x{h}bb.{f}", with: "500x500bb.png")
                              }
                              break
                         }
                    }
               }
               games.append(game)
          }
          games = games.sorted(by: { (g1, g2) -> Bool in
               g1.appName < g2.appName
          })
     }
}

struct App {
    var appId: String = ""
    var appName: String = ""
    var platforms: String = ""
    var iconUrl: String = ""
    var bundleId: String = ""
    var sku: String = ""
    var primaryLocale: String = ""
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
