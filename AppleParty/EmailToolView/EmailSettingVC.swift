//
//  EmailSettingVC.swift
//  AppleParty
//
//  Created by HTC on 2022/3/29.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa


struct EamilConfigs {
    var name: String = ""
    var addr: String = ""
    var pwd: String = ""
    var smtp: String = ""
}

var eamilConfigs: EamilConfigs? {
    get {
        let value = (try? APUtil.keychain.getString("APEmailSetting_Key")) ?? ""
        let arr = value.components(separatedBy: "|")
        guard arr.count == 4 else {
            return nil
        }
        return EamilConfigs(name: arr[0], addr: arr[1], pwd: arr[2], smtp: arr[3])
    }
    set {
        guard let newValue = newValue else { return }
        let value = "\(newValue.name)|\(newValue.addr)|\(newValue.pwd)|\(newValue.smtp)"
        try? APUtil.keychain.set(value, key: "APEmailSetting_Key")
    }
}

class EmailSettingVC: NSViewController {

    public var closeHandle: (() -> Void)?
    
    @IBOutlet weak var emailNameView: NSTextField!
    @IBOutlet weak var emailAddrView: NSTextField!
    @IBOutlet weak var emailPwdView: NSTextField!
    @IBOutlet weak var emailSMTPView: NSTextField!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func clickedCancelBtn(_ sender: Any) {
        closeHandle?()
    }
    
    @IBAction func clickedSubmitBtn(_ sender: Any) {
        
        eamilConfigs = EamilConfigs(name: emailNameView.stringValue, addr: emailAddrView.stringValue, pwd: emailPwdView.stringValue, smtp: emailSMTPView.stringValue)
        closeHandle?()
    }
    
}
