//
//  SettingVC.swift
//  AppleParty
//
//  Created by HTC on 2022/3/25.
//  Copyright © 2021 37 Mobile Games. All rights reserved.
//

import Cocoa

class APSettingVC: NSViewController {
    
    var isLoginViewShow: Bool {
        get { return false }
        set {
            sPasswordBtn.isHidden = newValue
            clearCacheBtn.isHidden = !newValue
        }
    }
    
    @IBOutlet weak var trusDeviceBtn: NSButton!
    @IBOutlet weak var sPasswordBtn: NSButton!
    @IBOutlet weak var clearCacheBtn: NSButton!
    
    @IBAction func clickedTrusDeviceBtn(_ sender: NSButton) {
        InfoCenter.shared.trusDevice = sender.state == .on ? true : false
    }
    
    @IBAction func clickedSPasswordBtn(_ sender: Any) {
        let sb = NSStoryboard(name: "APPasswordVC", bundle: Bundle(for: self.classForCoder))
        let pwdVC = sb.instantiateController(withIdentifier: "APPasswordVC") as? APPasswordVC
        pwdVC?.callBackFunc = { pwd in
            UserCenter.shared.developerKey = pwd
        }
        presentAsSheet(pwdVC!)
    }
    
    
    @IBAction func clickedClearCacheBtn(_ sender: NSButton) {
        // 清掉缓存
        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
        InfoCenter.shared.cookies = []
        APHUD.hide(message: "清掉缓存成功", view: self.view)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "App设置"
        trusDeviceBtn.state = InfoCenter.shared.trusDevice ? .on : .off
    }
    
}
