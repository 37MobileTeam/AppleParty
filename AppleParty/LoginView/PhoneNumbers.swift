//
//  PhoneNumbers.swift
//  AppleParty
//
//  Created by 易承 on 2021/6/2.
//

import Foundation

struct PNumber {
    var num: String
    var id: Int
}

// MARK: - 双重绑定手机号码
struct PhoneNumbers {
    var numbers: [PNumber]
    
    init(body: [String: Any]) {
        numbers = [PNumber]()
        let trustedPhoneNumbers = dictionaryArray(body["trustedPhoneNumbers"])
        for phone in trustedPhoneNumbers {
            numbers.append(PNumber(num: string(from: phone["numberWithDialCode"], defaultValue: "未知手机号"),
                                   id: int(from: phone["id"]) ?? 0 ))
        }
    }
}
