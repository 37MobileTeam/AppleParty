//
//  EmailToolVC.swift
//  AppleParty
//
//  Created by iHTC on 20211025.
//  Copyright © 2021 37 Mobile Games. All rights reserved.
//

import Cocoa


class EmailToolVC: NSViewController {

    var emailTitle: String? {
        didSet {
            if let text = emailTitle {
                emailTitleTF.stringValue = text
            }
        }
    }
    
    var emailContent: String? {
        didSet {
            if let text = emailContent {
                emailContentTextView.string = text
            }
        }
    }
    
    var attachmentFileUrl: URL? {
        didSet {
            if let url = attachmentFileUrl {
                fileURLs?.append(url)
                fileDropZoneView.setFile(url)
            }
        }
    }
    
    @IBOutlet weak var emailRecipientTF: NSTextField!
    @IBOutlet weak var rememberEmailButton: NSButton!
    @IBOutlet weak var emailTitleTF: NSTextField!
    @IBOutlet weak var emailSendButton: NSButton!
    @IBOutlet weak var emailContentTextView: NSTextView!
    @IBOutlet weak var emialContentView: NSScrollView!
    @IBOutlet weak var multipleFilesButton: NSButton!
    @IBOutlet weak var selectFilesButton: NSButton!
    @IBOutlet weak var clearnAllFilesButton: NSButton!
    @IBOutlet weak var selectFilesView: NSScrollView!
    @IBOutlet weak var selectilesTextView: NSTextView!
    
    private var fileDropZoneView = DropZoneView(fileTypes: [], text: "点击或拖拽文件到这里")
    private var fileURLs: [URL]?
    // 邮件地址
    private var emailsString: String {
        get { string(from: UserDefaults.standard.object(forKey: "EmailToolVC_RememberEmailString")) }
        set { UserDefaults.standard.setValue(newValue, forKey: "EmailToolVC_RememberEmailString") }
    }
    
    private lazy var settingPopover: NSPopover = {
        let settingPopover = NSPopover()
        let vc = EmailSettingVC()
        vc.closeHandle = {
            settingPopover.close()
        }
        settingPopover.contentViewController = vc
        return settingPopover
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    
    func setupUI() {
        
        if emailsString.count > 0 {
            emailRecipientTF.stringValue = emailsString
            rememberEmailButton.state = .on
        } else {
            rememberEmailButton.state = .off
        }
        
        fileDropZoneView.translatesAutoresizingMaskIntoConstraints = false
        fileDropZoneView.delegate = self
        view.addSubview(fileDropZoneView)
        fileDropZoneView.snp.makeConstraints { (make) in
            make.top.equalTo(multipleFilesButton.snp.bottom).offset(15)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-30)
        }
    
    }
    
    
    func validEmail() -> [String]? {
        
        let recipient = emailRecipientTF.stringValue
        guard recipient.count > 0 else {
            APHUD.hide(message: "收件人邮箱不能为空！", view: self.view, delayTime: 2)
            return nil
        }
        
        let allEmails = recipient.components(separatedBy: [";", "；", ",", "，"]).filter({!$0.isEmpty})
        let emails = allEmails.filter({ isEmailValid($0) })
        if emails.isEmpty {
            APHUD.hide(message: "收件人邮箱格式不正确！", view: self.view, delayTime: 2)
            return nil
        }
        
        return emails
    }
    
    @IBAction func clickedEmailSettingButton(_ sender: NSButton) {
        
        if settingPopover.isShown {
            settingPopover.performClose(self)
        }else {
            settingPopover.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.minY)
        }
    }
    
    
    @IBAction func sendEmailButton(_ sender: NSButton) {
        guard let config = eamilConfigs else {
            APHUD.hide(message: "请先设置邮箱服务器信息！", view: self.view, delayTime: 2)
            return
        }
        
        // 收件人
        guard let emails = validEmail() else {
            return
        }
        
        sender.isEnabled = false
        
        APHUD.show(message: "发送中...", view: self.view)
        
        var title = emailTitleTF.stringValue
        if title.isEmpty {
            title = "邮件助手"
        }
        
        let contents = "<p style='white-space:pre-wrap;'>\(emailContentTextView.textStorage?.string ?? "")</p>".replacingOccurrences(of: "\n", with: "<br>")
        
        var files = [String]()
        fileURLs?.forEach({ url in
            files.append(url.path)
        })

        // 发送邮件
        EmailUtils.autoSendAtts(subject: "AppleParty — \(title)", recipients: emails, htmlContent: contents, attachmentFiles: files, config: config) { error in
            DispatchQueue.main.async {
                sender.isEnabled = true
                APHUD.hide()
                debugPrint(error as Any)
                var msg = "邮箱发送成功~"
                if let err = error {
                    msg = "邮箱发送失败：\(String(describing: err))"
                }
                NSAlert.show(msg)
            }
        }
    }
    
    @IBAction func rememberEmail(_ sender: Any) {
        // 收件人
        guard validEmail() != nil else {
            return
        }
        
        emailsString = emailRecipientTF.stringValue
    }
    
    @IBAction func ChangeMultipleFiles(_ sender: NSButton) {
        
        clearnAllFiles(clearnAllFilesButton)
        
        if sender.state == .on {
            fileDropZoneView.isHidden = true
            selectFilesButton.isHidden = false
            clearnAllFilesButton.isHidden = false
            selectFilesView.isHidden = false
            
        } else {
            fileDropZoneView.reset()
            fileDropZoneView.isHidden = false
            selectFilesButton.isHidden = true
            clearnAllFilesButton.isHidden = true
            selectFilesView.isHidden = true
        }
    }
    
    @IBAction func clearnAllFiles(_ sender: NSButton) {
        fileURLs = []
        selectilesTextView.string = ""
    }
    
    @IBAction func selectFiles(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        
        openPanel.beginSheetModal(for: self.view.window!) { [self] (modalResponse) in
            if modalResponse == .OK {
                self.fileURLs?.append(contentsOf: openPanel.urls)
                self.updateFilesView()
            }
        }
    }
    
    func updateFilesView() {
        fileURLs?.forEach({ file in
            let path = file.lastPathComponent
            selectilesTextView.string.append(path + "\n")
        })
        
        selectilesTextView.scrollRangeToVisible(NSMakeRange(selectilesTextView.string.count, 0))
    }
}


// MARK: - DropZoneViewDelegate
extension EmailToolVC: DropZoneViewDelegate {
    
    func receivedFile(dropZoneView: DropZoneView, fileURL: URL) {
        fileURLs = [fileURL]
    }
    
    func receivedMouseDown(dropZoneView: DropZoneView, theEvent: NSEvent) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        
        openPanel.beginSheetModal(for: self.view.window!) { (modalResponse) in
            if modalResponse == .OK {
                if let fileURL = openPanel.url {
                    self.fileURLs = [fileURL]
                    dropZoneView.setFile(fileURL)
                }
            }
        }
    }
}
