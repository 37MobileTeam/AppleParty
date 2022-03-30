//
//  TierStemParser.swift
//  AppleParty
//
//  Created by 易承 on 2021/6/1.
//

import Foundation

struct TierStemParser {
    
    static func loadJson() {
        if let filePath = Bundle.main.path(forResource: "TierStem", ofType: "txt"), let jsonData = NSData(contentsOfFile: filePath) {
            if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData as Data), let dict = jsonObject as? [String: Any] {
                let data = dictionary(dict["data"])
                let pricingTiers = dictionaryArray(data["pricingTiers"])
                var result = [String: Any]()
                for ts in pricingTiers {
                    let pricingInfo = dictionaryArray(ts["pricingInfo"])
                    let tierStem = string(from: ts["tierStem"])
                    let newpi = pricingInfo.filter { (value) -> Bool in
                        string(from: value["countryCode"]) == "CN"
                    }
                    let retailPrice = string(from: newpi.first?["retailPrice"])
                    result[tierStem] = retailPrice
                }
                debugPrint(result)
            }
        }
    }
}
