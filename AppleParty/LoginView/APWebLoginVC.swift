//
//  APWebLoginVC.swift
//  AppleParty
//
//  Created by HTC on 2024/10/29.
//  Copyright © 2024 37 Mobile Games. All rights reserved.
//

import Cocoa

class APWebLoginVC: NSViewController {

    public var cancelHandle: (() -> Void)?
    public var successHandle: (() -> Void)?
    private var webCore: AppleWebLoginCore? = nil
    
    @IBOutlet weak var loginBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var indicatorView: NSProgressIndicator!
    @IBOutlet weak var tipsWarningView: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func clickedCancelBtn(_ sender: NSButton) {
        closeView()
        cancelHandle?()
    }
    
    @IBAction func clickedLoginBtn(_ sender: NSButton) {
        validateSession()
    }
    
    // 判断是登陆态是否过期
    func validateSession() {
        viewEnabled(false)
        APClient.signInSession.request { [weak self] result, response, error in
            self?.viewEnabled(true)
            let code = response?.statusCode
            switch code {
            case 200, 201:
                UserCenter.shared.isAuthorized = true
                self?.successHandle?()
                self?.closeView()
            default:
                let errors = dictionaryArray(result["serviceErrors"])
                let msg = string(from: errors.first?["message"])
                self?.showTips(msg.isEmpty ? error.debugDescription : msg)
                // 隐藏按钮透视显示
                self?.cancelBtn.isEnabled = false
                self?.loginBtn.isEnabled = false
                self?.loginWithWeb()
            }
        }
    }
    
    func loginWithWeb() {
        let appleWebLoginCore = AppleWebLoginCore()
        // 将 webView 添加到视图层次结构中
        self.view.addSubview(appleWebLoginCore.webView)
        
        let closeButton = NSButton(title: "取消", target: self, action: #selector(closeButtonClicked))
        closeButton.attributedTitle = NSAttributedString(string: "取消", attributes: [NSAttributedString.Key.foregroundColor: NSColor.gray])
        closeButton.keyEquivalent = "\u{1B}"  // `esc` 快捷键
        appleWebLoginCore.webView.addSubview(closeButton)
        
        // 设置 webView 的约束以适应视图
        appleWebLoginCore.webView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            appleWebLoginCore.webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            appleWebLoginCore.webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            appleWebLoginCore.webView.topAnchor.constraint(equalTo: self.view.topAnchor),
            appleWebLoginCore.webView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            
            closeButton.trailingAnchor.constraint(equalTo: appleWebLoginCore.webView.trailingAnchor, constant: -10),
            closeButton.topAnchor.constraint(equalTo: appleWebLoginCore.webView.topAnchor, constant: 10)
        ])
        
        // 关闭按钮
        
        
        appleWebLoginCore.installFirstLoadCompleteTrap {
            // 处理首次加载完成的逻辑
            print("First load complete")
        }

        appleWebLoginCore.installCredentialPopulationTrap { token, cookies  in
            // 处理凭据填充的逻辑
            print("Received cookies: \(cookies)")
            print("Received token: \(token)")
            
            if let cks = APClientSession.shared.config.httpCookieStorage?.cookies {
                for ck in cks {
                    APClientSession.shared.config.httpCookieStorage?.deleteCookie(ck)
                }
            }
            for cookie in cookies {
                APClientSession.shared.config.httpCookieStorage?.setCookie(cookie)
            }
//            APClientSession.shared.config.headers.update(name: "Cookie", value: "myacinfo=\(token);")
            self.validateSession()
        }
        self.webCore = appleWebLoginCore
    }
    
    @objc func closeButtonClicked() {
        // 处理关闭按钮的点击事件
        print("关闭按钮被点击")
        closeView()
    }
    
    func viewEnabled(_ isEnabled: Bool) {
        showTips("")
        loginBtn.isEnabled = isEnabled
        isEnabled ? indicatorView.stopAnimation(nil) : indicatorView.startAnimation(nil)
    }
    
    func showTips(_ text: String) {
        if text.isEmpty {
            tipsWarningView.isHidden = true
            tipsWarningView.stringValue = ""
        } else {
            tipsWarningView.stringValue = text
            tipsWarningView.isHidden = false
        }
    }
    
    func closeView() {
        guard let window = view.window, let parent = window.sheetParent
        else { return }
        parent.endSheet(window)
    }
    
}
