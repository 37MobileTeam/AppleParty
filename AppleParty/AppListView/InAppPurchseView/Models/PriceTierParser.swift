//
//  PriceTierParser.swift
//  AppleParty
//
//  Created by HTC on 2022/11/18.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Foundation


struct PriceTierParser {
    
    static let tiers = pricingMatrix()
    
    static func pricingMatrix() -> [String: [String: String]]{
        var result = [String: [String: String]]()
        if let filePath = Bundle.main.path(forResource: "AppStorePricingMatrix", ofType: "json"),
            let jsonData = NSData(contentsOfFile: filePath) {
            if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData as Data), let dict = jsonObject as? [String: Any] {
                let data = dictionary(dict["data"])
                let pricingTiers = dictionaryArray(data["pricingTiers"])
                var tiers = [String: String]()
                for ts in pricingTiers {
                    let pricingInfo = dictionaryArray(ts["pricingInfo"])
                    let tierStem = string(from: ts["tierStem"])
                    for info in pricingInfo {
                        let country = info["countryCode"] as! String
                        let retailPrice = info["retailPrice"] as! NSNumber
                        tiers[country] = "\(retailPrice)"
                    }
                    result[tierStem] = tiers
                }
            }
        }
        return result
    }
    
    static func priceTiers(_ countryCode: String) -> [String: String] {
        var checkPrice = [String: String]()
        for tier in PriceTierParser.tiers {
            let key = tier.key
            if let price = tier.value[countryCode] {
                checkPrice[key] = price
            }
        }
        return checkPrice
    }
}
