//
//  APLogin2FAVC.swift
//  AppleParty
//
//  Created by HTC on 2022/3/17.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APLogin2FAVC: NSViewController {
    
    public var cancelHandle: (() -> Void)?
    public var successHandle: (() -> Void)?
    
    @IBOutlet weak var phoneListBtn: NSPopUpButton!
    @IBOutlet weak var sendCodeBtn: NSButton!
    @IBOutlet weak var voiceCodeBtn: NSButton!
    @IBOutlet weak var phoneCodeView: NSTextField!
    @IBOutlet weak var tipsWarningView: NSTextField!
    @IBOutlet weak var trusDeviceBtn: NSButton!
    @IBOutlet weak var indicatorView: NSProgressIndicator!
    @IBOutlet weak var verifyBtn: NSButton!
    
    private var numbers: [PNumber] = [] //验证手机号码列表
    private var isPhoneSecurity = false //是否通过手机验证码来验证
    // 验证码倒计时
    private var verifyCodeTimer: Timer?
    private var lastTime: Int = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phoneCodeView.delegate = self
        fetchPhoneList()
        trusDeviceBtn.state = InfoCenter.shared.trusDevice ? .on : .off
    }
    
    @IBAction func clickedCancelBtn(_ sender: NSButton) {
        closeView()
        cancelHandle?()
    }
    
    @IBAction func clickedSendCodeBtn(_ sender: NSButton) {
        submitSecurityCode()
    }
    
    
    @IBAction func changeVoiceCodeBtn(_ sender: NSButton) {
        sendCodeBtn.title = sender.state == .on ? "拨打语音验证码" : "发送短信验证码"
    }
    
    
    @IBAction func clickedVerifyBtn(_ sender: NSButton) {
        verifySecurityCode()
    }
    
    @IBAction func clickedTrusDeviceBtn(_ sender: NSButton) {
        InfoCenter.shared.trusDevice = sender.state == .on ? true : false
    }
}


// MARK: - 网络请求
extension APLogin2FAVC {
    
    func fetchPhoneList() {
        APClient.verifySecurityPhone(mode: "sms", phoneid: 0).request(showLoading: true) { [weak self] result, response, error in
            if let err = error, let type = APClientErrorCode(rawValue: err.code) {
                switch type {
                case .privacyAcknowledgementRequired:
                    // 传了无效phoneid，进入选择手机号的流程
                    self?.phoneListBtn.removeAllItems()
                    let model = PhoneNumbers(body: result)
                    self?.numbers = model.numbers
                    for number in model.numbers {
                        self?.phoneListBtn.addItem(withTitle: number.num)
                    }
                    self?.phoneListBtn.selectItem(at: 0)
                    self?.showTips("一条包含验证码的信息已发送至您的设备。可输入设备验证码后点击验证以继续。\n或者点击“发送短信验证码”获取短信验证码。")
                default:
                    APHUD.hide(message: err.localizedDescription)
                }
            }
        }
    }
    
    func submitSecurityCode() {
        isPhoneSecurity = true
        let mode = voiceCodeBtn.state == .on ? "voice" : "sms"
        let phoneId = numbers[phoneListBtn.indexOfSelectedItem].id
        APClient.verifySecurityPhone(mode: mode, phoneid: phoneId).request(showLoading: true) { [weak self] result, response, error in
            let code = response?.statusCode
            if [200, 423].contains(code) {
                let msg = self?.voiceCodeBtn.state == .on ? "请求拨打语音电话，请收听~" : "验证码已发送，请查收~"
                self?.showTips(msg)
                self?.verifyCodeCountdown()
            } else {
                self?.showTips("\(code ?? 0),\(error.debugDescription)")
            }
        }
    }
    
    func verifySecurityCode() {
        let code = phoneCodeView.stringValue
        let phoneId = numbers[phoneListBtn.indexOfSelectedItem].id
        let mode = voiceCodeBtn.state == .on ? "voice" : "sms"
        let type = isPhoneSecurity ? APClient.SecurityCode.sms(code: code, phoneNumberId: phoneId, mode: mode) : APClient.SecurityCode.device(code: code)
        
        viewEnabled(false)
        APClient.submitSecurityCode(code: type).request { [weak self] result, response, error in
            self?.viewEnabled(true)
            let code = response?.statusCode
            switch code {
                case 200, 201, 202, 203, 204:
                    self?.validateSession()
                case 400:
                    let errors = dictionaryArray(result["service_errors"])
                    let msg = string(from: errors.first?["message"])
                    self?.showTips(msg)
                default:
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
                self?.successHandle?()
                self?.closeView()
            default:
                let errors = dictionaryArray(result["serviceErrors"])
                let msg = string(from: errors.first?["message"])
                self?.showTips(msg.isEmpty ? error.debugDescription : msg)
            }
        }
    }
}

// MARK: - 内部方法
extension APLogin2FAVC {
    
    func closeView() {
        guard let window = view.window, let parent = window.sheetParent
        else { return }
        parent.endSheet(window)
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
    
    func viewEnabled(_ isEnabled: Bool) {
        showTips("")
        verifyBtn.isEnabled = isEnabled
        isEnabled ? indicatorView.stopAnimation(nil) : indicatorView.startAnimation(nil)
    }
    
    func verifyCodeCountdown() {
        self.lastTime = 30
        self.sendCodeBtn.title = "\(self.lastTime)s 后重试"
        self.sendCodeBtn.isEnabled = false
        self.verifyCodeTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.verifyCodeTime), userInfo: nil, repeats: true)
    }
    
    // 验证码倒计时
    @objc func verifyCodeTime() {
        lastTime -= 1
        sendCodeBtn.title = "\(self.lastTime)s 后重试"
        if lastTime <= 0 {
            sendCodeBtn.title = "重新发送验证码"
            sendCodeBtn.isEnabled = true
            verifyCodeTimer?.invalidate()
        }
    }
}

// MARK: - NSTextFieldDelegate
extension APLogin2FAVC: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        if phoneCodeView.stringValue.count == 6 {
            verifyBtn.isEnabled = true
        } else {
            verifyBtn.isEnabled = false
        }
    }
}
