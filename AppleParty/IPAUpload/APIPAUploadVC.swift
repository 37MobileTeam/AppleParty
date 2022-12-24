//
//  APIPAUploadVC.swift
//  AppleParty
//
//  Created by HTC on 2022/5/12.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APIPAUploadVC: NSViewController {

    @IBOutlet weak var appIdTextView: NSTextField!
    @IBOutlet weak var appIdTextField: NSTextField!
    @IBOutlet weak var spasswordLbl: NSTextField!
    @IBOutlet weak var submitBtn: NSButton!
    
    //通过外界传入的 apple id时，不需要用户填写
    var apple_id: String? {
        didSet {
            if let appId = apple_id {
                appIdTextView.stringValue = appId
                appIdTextView.isHidden = false
                appIdTextField.isHidden = true
            } else {
                appIdTextView.stringValue = ""
                appIdTextView.isHidden = true
                appIdTextField.isHidden = false
            }
        }
    }
    
    private var ipaFileURL: URL?
    private var fileDropZoneView = DropZoneView(fileTypes: [".ipa"], text: "点击或拖拽IPA到这里")
    private var uploadModel = XMLModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateSPasswordUI()
    }
    
    func setupUI() {
        
        fileDropZoneView.translatesAutoresizingMaskIntoConstraints = false
        fileDropZoneView.delegate = self
        view.addSubview(fileDropZoneView)
        fileDropZoneView.snp.makeConstraints { (make) in
            make.top.equalTo(submitBtn.snp.bottom).offset(15)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-30)
        }
    }
    
    func updateSPasswordUI() {
        if let sp = UserCenter.shared.currentSPassword {
            spasswordLbl.stringValue = "(当前选择：\(sp.account))"
        } else {
            spasswordLbl.stringValue = "(错误：当前未指定专用密码！)"
        }
    }
    
    @IBAction func clickedSPasswordBtn(_ sender: NSButton) {
        let vc = APSPasswordSettingVC()
        vc.updateCompletion = { [weak self] ps in
            self?.updateSPasswordUI()
        }
        presentAsSheet(vc)
    }
 
    @IBAction func clickedSubmitBtn(_ sender: NSButton) {
        uploadIpaFile()
    }
    
}

// MARK: - Private Method
extension APIPAUploadVC {
    
    private func uploadIpaFile() {
        
        var appId = appIdTextField.stringValue
        if let appleId = apple_id {
            appId = appleId
        }
        guard !appId.isEmpty else {
            APHUD.hide(message: "请先填写 app id ~", delayTime: 1)
            return
        }

        guard let sp = UserCenter.shared.currentSPassword else {
            let vc = APSPasswordSettingVC()
            vc.updateCompletion = { [weak self] spassword in
                self?.uploadIpaFile()
            }
            presentAsSheet(vc)
            APHUD.hide(message: "请先设置或指定专用密码~", delayTime: 1)
            return
        }
        
        guard let ipaFileURL = ipaFileURL else {
            APHUD.hide(message: "请先上传 ipa 文件~", delayTime: 1)
            return
        }
        
        APHUD.show(message: "上传中", view: self.view)
        
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            
            uploadModel = XMLModel()
            uploadModel.apple_id = appId
            uploadModel.ipa_size = ipaFileURL.fileSize()
            uploadModel.ipa_md5 = ipaFileURL.fileMD5() ?? ""
            uploadModel.filePaths = ["ipa.ipa": ipaFileURL.path]
            
            // 获取创建 itms 文件的路径
            let filePath = XMLManager.getIpaPath(appId)
            
            // 先删除旧的文档
            XMLManager.deleteITMS(filePath)
            
            uploadModel.createIpaFile(directoryPath: filePath)
            
            let result = XMLManager.uploadITMS(account: sp.account, pwd: sp.password, filePath: filePath)
            
            DispatchQueue.main.async {
                APHUD.hide()
                self.closeSelfAndCallBack(result)
            }
        }
        
    }
    
    
    func closeSelfAndCallBack(_ result: (Int32, String?)) {
        if result.0 == 0 {
            NSAlert.show("ipa文件上传成功！稍后可在苹果后台查看~")
        }else {
            let sb = NSStoryboard(name: "APDebugVC", bundle: Bundle(for: self.classForCoder))
            let newWC = sb.instantiateController(withIdentifier: "APDebugWC") as? NSWindowController
            let logVC = newWC?.contentViewController as? APDebugVC
            newWC?.window?.title = "ipa上传错误日志"
            logVC?.debugLog = result.1 ?? ""
            newWC?.showWindow(self)
        }
    }
}


// MARK: - DropZoneViewDelegate
extension APIPAUploadVC: DropZoneViewDelegate {
    
    func receivedFile(dropZoneView: DropZoneView, fileURL: URL) {
        ipaFileURL = fileURL
    }
    
    func receivedMouseDown(dropZoneView: DropZoneView, theEvent: NSEvent) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedFileTypes = ["ipa"]
        
        openPanel.beginSheetModal(for: self.view.window!) { (modalResponse) in
            if modalResponse == .OK {
                if let fileURL = openPanel.url {
                    self.ipaFileURL = fileURL
                    dropZoneView.setFile(fileURL)
                }
            }
        }
    }
}
