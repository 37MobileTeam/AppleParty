//
//  APRootWC.swift
//  AppleParty
//
//  Created by HTC on 2022/3/11.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APRootWC: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        setupUI()
    }
    
    func setupUI() {
        self.window?.title = "AppleParty"
        if #available(macOS 11.0, *) {
            self.window?.subtitle = "37 Mobile Games"
        }
    }

    @IBAction func clickedAccountItem(_ sender: NSToolbarItem?) {
        // 登陆时，显示切换账号
        if UserCenter.shared.isAuthorized {
            if let providers = UserCenter.shared.accountProviders["availableProviders"] as? [[String: Any]] {
                var accountList: [Provider] = []
                providers.forEach { provider in
                    accountList.append(Provider(name: provider["name"] as! String, providerId: String(provider["providerId"] as! Int), publicProviderId: provider["publicProviderId"] as! String))
                }
                
                accountList.append(Provider(name: "账号登出", providerId: "", publicProviderId: ""))
                
                let listVC = APSwichAccountPopover()
                listVC.accounts = accountList
                listVC.selectHandle = { [weak self] row in
                    guard row >= 0, row < accountList.count else {
                        return
                    }
                    let publicProviderId = accountList[row].publicProviderId
                    self?.switchAccount(publicProviderId)
                }
                let pannel = NSPanel(contentViewController: listVC)
                pannel.setFrame(NSRect(origin: .zero, size: NSSize(width: 300, height: 350)), display: true)
                window?.beginSheet(pannel, completionHandler: nil)
            } else {
                APHUD.hide(message:"获取登陆账号信息异常~")
            }
            
        } else {
            let vc = APLoginVC()
            vc.successHandle = { [weak self] in
                self?.fetchAccountTeamInfo()
                self?.window?.title = UserCenter.shared.developerName
                if #available(macOS 11.0, *) {
                    self?.window?.subtitle = UserCenter.shared.accountEmail
                }
            }
            let pannel = NSPanel(contentViewController: vc)
            pannel.setFrame(NSRect(origin: .zero, size: NSSize(width: 500, height: 330)), display: true)
            window?.beginSheet(pannel, completionHandler: nil)
        }
    }
    
    @IBAction func clickedSettingsItem(_ sender: Any) {
        let vc = APSettingVC()
        let window = NSWindow(contentViewController: vc)
        let wc = NSWindowController(window: window)
        wc.showWindow(self)
        vc.isLoginViewShow = !UserCenter.shared.isAuthorized
    }
    
    @IBAction func clickedGithubItem(_ sender: Any) {
        let url = URL(string: kApplePartyGitHub)
        NSWorkspace.shared.open(url!)
    }
    
    @IBAction func clicedFeedbackItem(_ sender: Any) {
        let url = URL(string: kApplePartyNewIssues)
        NSWorkspace.shared.open(url!)
    }
    
    @IBAction func cliced37MobileGamesItem(_ sender: Any) {
        let url = URL(string: k37MobileGamesSite)
        NSWorkspace.shared.open(url!)
    }
    
    
    @IBAction func cliced37iOSTeamItem(_ sender: Any) {
        let url = URL(string: k37iOSTeamJueJinSite)
        NSWorkspace.shared.open(url!)
    }
}


extension APRootWC {
    
    func switchAccount(_ publicProviderId: String) {
        guard publicProviderId.count > 0 else {
            UserCenter.shared.isAutoLogin = false
            UserCenter.shared.isAuthorized = false
            // 清掉缓存
            //HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
            InfoCenter.shared.cookies = []
            setupUI()
            return
        }
        
        APClient.switchProvider(publicProviderId: publicProviderId).request(showLoading: true) { [weak self] result, response, error in
            guard let err = error else {
                self?.validateSession()
                return
            }
            APHUD.hide(message: err.localizedDescription)
        }
    }
    
    func validateSession() {
        APClient.signInSession.request(showLoading: true) { [weak self] result, response, error in
            guard let err = error else {
                UserCenter.shared.isAuthorized = true
                self?.window?.title = UserCenter.shared.developerName
                if #available(macOS 11.0, *) {
                    self?.window?.subtitle = UserCenter.shared.accountEmail
                }
                self?.fetchAccountTeamInfo()
                return
            }
            APHUD.hide(message: err.localizedDescription)
        }
    }
    
    func fetchAccountTeamInfo() {
        // 获取开发者 Team id 信息
        APClient.ascProvider.request(completionHandler: nil)
    }
}
