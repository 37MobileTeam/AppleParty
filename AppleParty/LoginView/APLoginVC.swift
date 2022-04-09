//
//  APLoginVC.swift
//  AppleParty
//
//  Created by HTC on 2022/3/17.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APLoginVC: NSViewController {

    public var cancelHandle: (() -> Void)?
    public var successHandle: (() -> Void)?
    
    @IBOutlet weak var accountView: NSTextField!
    @IBOutlet weak var passwordView: NSSecureTextField!
    // 历史账号
    @IBOutlet weak var historyBox: NSBox!
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var tipsWarningView: NSTextField!
    @IBOutlet weak var autoLoginBtn: NSButton!
    @IBOutlet weak var indicatorView: NSProgressIndicator!
    @IBOutlet weak var loginBtn: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        accountView.delegate = self
        passwordView.delegate = self
        tipsWarningView.maximumNumberOfLines = 5
        
        // 最近登录的账号
        let user = UserCenter.shared.loginedUser
        let name = user.appleid
        let pwd = user.password
        guard name.count > 0, pwd.count > 0 else { return }
        accountView.stringValue = name
        passwordView.stringValue = pwd
        viewEnabled(true)
        
        // 如果需要自动登录
        if UserCenter.shared.isAutoLogin || UserCenter.shared.isFirstTime {
            loginAccount()
            UserCenter.shared.isFirstTime = false
        }
    }
    
    @IBAction func clickedCancelBtn(_ sender: NSButton) {
        closeView()
        cancelHandle?()
    }
    
    
    @IBAction func showAccountHistoryList(_ sender: Any) {
        if historyBox.isHidden {
            tableView.delegate = self
            tableView.dataSource = self
            tableView.reloadData()
        }
        historyBox.isHidden = !historyBox.isHidden
    }
    
    @IBAction func clickedLoginBtn(_ sender: NSButton) {
        loginAccount()
    }
}


// MARK: - 网络请求
extension APLoginVC {
    
    func loginAccount() {
        if accountView.stringValue.isEmpty {
            showTips("苹果账号不能为空!")
            return
        }
        if passwordView.stringValue.isEmpty {
            showTips("密码不能为空!")
            return
        }
        
        viewEnabled(false)
        
        let account = accountView.stringValue
        let pwd = passwordView.stringValue
        
        APClient.signIn(account: account, password: pwd).request { [weak self] result, response, error in
            self?.viewEnabled(true)
            if let err = error, let type = APClientErrorCode(rawValue: err.code) {
                switch type {
                case .notAuthorized:
                    self?.showTips("Apple ID 或密码不正确")
                case .twoStepOrFactor:
                    // 保存账号密码
                    if self?.autoLoginBtn.state == .on {
                        UserCenter.shared.isAutoLogin = true
                        UserCenter.shared.loginedUser = User(appleid: account, password: pwd)
                    }
                    // 双重认证
                    let vc = APLogin2FAVC()
                    vc.cancelHandle = { [weak self] in
                        self?.viewEnabled(true)
                    }
                    vc.successHandle = { [weak self] in
                        self?.trusDevice()
                        self?.successHandle?()
                        self?.closeView()
                    }
                    let pannel = NSPanel(contentViewController: vc)
                    pannel.setFrame(NSRect(origin: .zero, size: NSSize(width: 500, height: 360)), display: true)
                    self?.view.window?.beginSheet(pannel, completionHandler: nil)
                default:
                    self?.showTips(err.localizedDescription)
                }
                return
            }
            let code = response?.statusCode
            // 登陆态有效
            if code == 200 {
                // 保存账号密码
                if self?.autoLoginBtn.state == .on {
                    UserCenter.shared.isAutoLogin = true
                    UserCenter.shared.loginedUser = User(appleid: account, password: pwd)
                }
                self?.validateSession()
            } else {
                self?.showTips("\(code ?? 0),\(error.debugDescription)")
            }
        }
    }
    
    func validateSession() {
        viewEnabled(false)
        APClient.signInSession.request { [weak self] result, response, error in
            self?.viewEnabled(true)
            let code = response?.statusCode
            switch code {
            case 200, 201:
                UserCenter.shared.isAuthorized = true
                self?.trusDevice()
                self?.successHandle?()
                self?.closeView()
            default:
                let errors = dictionaryArray(result["serviceErrors"])
                let msg = string(from: errors.first?["message"])
                self?.showTips(msg.isEmpty ? error.debugDescription : msg)
            }
        }
    }
    
    func trusDevice() {
        guard InfoCenter.shared.trusDevice else { return}
        
        APClient.trusDevice(isTrus: true).request { result, response, error in
            if response?.statusCode == 204 {
                debugPrint("信任设备成功~")
            }
        }
    }
    
}


// MARK: - 内部方法
extension APLoginVC {
    
    func showTips(_ text: String) {
        if text.isEmpty {
            tipsWarningView.isHidden = true
            tipsWarningView.stringValue = ""
        } else {
            tipsWarningView.stringValue = text
            tipsWarningView.isHidden = false
        }
    }
    
    func viewEnabled(_ isEnabled: Bool) {
        showTips("")
        loginBtn.isEnabled = isEnabled
        historyBox.isHidden = true
        isEnabled ? indicatorView.stopAnimation(nil) : indicatorView.startAnimation(nil)
    }
    
    func closeView() {
        guard let window = view.window, let parent = window.sheetParent
        else { return }
        parent.endSheet(window)
    }
    
}

// MARK: - NSTextFieldDelegate
extension APLoginVC: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        if !accountView.stringValue.isEmpty && !passwordView.stringValue.isEmpty {
            loginBtn.isEnabled = true
        } else {
            loginBtn.isEnabled = false
            showTips("")
        }
    }
}

// MARK: - NSTableViewDelegate
extension APLoginVC: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return UserCenter.shared.historyUser.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "nameColumn") {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = UserCenter.shared.historyUser[row].appleid
            return cellView
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification){
        let tableView = notification.object as! NSTableView
        let clickedRow = tableView.selectedRow
        guard clickedRow >= 0 else {
            return
        }
        tableView.deselectRow(clickedRow)
        accountView.stringValue = UserCenter.shared.historyUser[clickedRow].appleid
        passwordView.stringValue = UserCenter.shared.historyUser[clickedRow].password
        showAccountHistoryList(clickedRow)
    }
}
