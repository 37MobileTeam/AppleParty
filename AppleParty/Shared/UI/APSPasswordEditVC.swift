//
//  APSPasswordEditVC.swift
//  AppleParty
//
//  Created by HTC on 2022/5/18.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APSPasswordEditVC: NSViewController {
    
    @IBOutlet weak var titleLbl: NSTextField!
    @IBOutlet var accountTextView: NSTextField!
    @IBOutlet var passwordTextView: NSTextField!
    @IBOutlet weak var usePasswordBtn: NSButton!

    public var titleString: String?
    public var spassword: SPassword?
    public var updateCompletion: ((_ model: SPassword) -> Void)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let text = titleString {
            titleLbl.stringValue = text
        }
        
        if let model = spassword {
            accountTextView.stringValue = model.account
            passwordTextView.stringValue = model.password
            usePasswordBtn.state = model.isused ? .on : .off
        } else {
            // 新建时，默认读取当前账号的邮件名
            accountTextView.stringValue = UserCenter.shared.loginedUser.appleid
        }
    }
    
    @IBAction func clickedCancelBtn(_ sender: Any) {
        dismiss(self)
    }
    
    @IBAction func clickedSaveBtn(_ sender: Any) {
        let account = accountTextView.stringValue.trim()
        let password = passwordTextView.stringValue.trim()
        
        guard account.isNotEmpty, password.isNotEmpty else {
            APHUD.hide(message: "账号邮箱和专用密码不能为空！", view: view, delayTime: 1)
            return
        }
        
        if let block = updateCompletion {
            block(SPassword(account: account, password: password, isused: usePasswordBtn.state == .on))
        }
        dismiss(self)
    }
    
}
