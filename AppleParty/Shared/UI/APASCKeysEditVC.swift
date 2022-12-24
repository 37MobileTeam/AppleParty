//
//  APSPasswordEditVC.swift
//  AppleParty
//
//  Created by HTC on 2022/5/18.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APASCKeysEditVC: NSViewController {
    
    @IBOutlet weak var titleLbl: NSTextField!
    @IBOutlet var accountTextView: NSTextField!
    @IBOutlet var issuerIDTextView: NSTextField!
    @IBOutlet var privateKeyIDTextView: NSTextField!
    @IBOutlet var privateKeyTextView: NSTextField!
    @IBOutlet weak var usePasswordBtn: NSButton!

    public var titleString: String?
    public var spassword: AppStoreConnectKey?
    public var updateCompletion: ((_ model: AppStoreConnectKey) -> Void)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let text = titleString {
            titleLbl.stringValue = text
        }
        
        if let model = spassword {
            accountTextView.stringValue = model.aliasName
            issuerIDTextView.stringValue = model.issuerID
            privateKeyIDTextView.stringValue = model.privateKeyID
            privateKeyTextView.stringValue = model.privateKey
            usePasswordBtn.state = model.isused ? .on : .off
        } else {
            // 新建时，默认读取当前开发者名称
            accountTextView.stringValue = UserCenter.shared.developerName
        }
    }
    
    @IBAction func clickedInputFileBtn(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["p8", "P8"]
        
        openPanel.beginSheetModal(for: self.view.window!) { (modalResponse) in
            if modalResponse == .OK {
                if let fileURL = openPanel.url {
                    self.handleP8fileContent(fileURL)
                }
            }
        }
    }
    
    @IBAction func clickedCancelBtn(_ sender: Any) {
        dismiss(self)
    }
    
    @IBAction func clickedSaveBtn(_ sender: Any) {
        let account = accountTextView.stringValue.trim()
        let issuerID = issuerIDTextView.stringValue.trim()
        let privateKeyID = privateKeyIDTextView.stringValue.trim()
        let privateKey = privateKeyTextView.stringValue.trim()
        
        guard account.isNotEmpty, issuerID.isNotEmpty, privateKeyID.isNotEmpty, privateKey.isNotEmpty else {
            APHUD.hide(message: "所有配置项不能为空！", view: view, delayTime: 1)
            return
        }
        
        if let block = updateCompletion {
            block(AppStoreConnectKey(aliasName: account, issuerID: issuerID, privateKeyID: privateKeyID, privateKey: privateKey, isused: usePasswordBtn.state == .on))
        }
        dismiss(self)
    }
    
    func handleP8fileContent(_ url: URL) {
        guard let data = try? Data(contentsOf: url),
              var content = String(data: data, encoding: .utf8) else {
            APHUD.hide(message: "p8文件内容读取失败！请检查文件是否完整！", delayTime: 1)
            return
        }
        let begin = "-----BEGIN PRIVATE KEY-----"
        let end = "-----END PRIVATE KEY-----"
        content = content.replacingOccurrences(of: begin, with: "")
        content = content.replacingOccurrences(of: end, with: "")
        content = content.replacingOccurrences(of: "\n", with: "")
        privateKeyTextView.stringValue = content
    }
    
}
