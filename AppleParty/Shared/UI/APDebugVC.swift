//
//  APDebugVC.swift
//  AppleParty
//
//  Created by HTC on 2022/3/21.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APDebugVC: NSViewController {

    @IBOutlet var debugTextView: NSTextView!
    @IBOutlet weak var refreshBtn: NSButton!
    @IBOutlet weak var shareBtn: NSButton!
    
    var debugLog: String = "" {
        didSet {
            uploadData()
        }
    }
    
    var fileURL: URL? {
        didSet {
            refreshBtn.isHidden = false
            reloadFileLogs()
        }
    }
    
    // Menu
    private lazy var editMenu: NSMenu = {
        let menu = NSMenu()
        let editMenuItems = [
            NSMenuItem(title: "邮件发送", action: #selector(emailShare), keyEquivalent: ""),
            NSMenuItem(title: "隔空投送", action: #selector(airDropShare), keyEquivalent: ""),
            NSMenuItem(title: "其它方式", action: #selector(otherShare), keyEquivalent: ""),
        ]
        for editMenuItem in editMenuItems {
            menu.addItem(editMenuItem)
        }
        return menu
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func clickedRefreshBtn(_ sender: Any) {
        reloadFileLogs()
    }
    
    @IBAction func clickedShareBtn(_ sender: NSButton) {
        let p = NSPoint(x: sender.frame.width, y: 0) //按钮右边
        self.editMenu.popUp(positioning: nil, at: p, in: sender)
    }
    
}


extension APDebugVC {
    
    func uploadData() {
        DispatchQueue.main.async {
            self.debugTextView.string = self.debugLog
            self.debugTextView.scrollRangeToVisible(NSMakeRange(self.debugTextView.string.count, 0))
        }
    }
    
    
    func reloadFileLogs() {
        guard let file = fileURL, let logs = try? String(contentsOf: file, encoding: .utf8) else {
            debugTextView.string = "读取日志失败！\(String(describing: fileURL?.path))"
            return
        }
        debugLog = logs
    }
    
    func getTextFileURL(text: String) -> URL? {
        
        guard let data = text.data(using: .utf8) else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmm"
        let date = dateFormatter.string(from: Date())
        let filename = "AppleParty-Logs_\(date).txt"
        
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(filename)

        do {
            try data.write(to: tempURL, options: .atomic)

            return tempURL
        } catch {
            assertionFailure("Failed to write temporary URL for pasteboard: \(String(describing: error))")
            return nil
        }
    }
}


extension APDebugVC {
    
    @objc func emailShare() {
        let text = debugTextView.string
        let mainStoryBoard = NSStoryboard(name: "EmailTool", bundle: nil)
        let windowController = mainStoryBoard.instantiateController(withIdentifier: "EmailTool") as! NSWindowController
        let controller = windowController.contentViewController as! EmailToolVC
        controller.emailTitle = "苹果派-错误日志"
        controller.emailContent = text
        controller.attachmentFileUrl = getTextFileURL(text: text)
        windowController.showWindow(self)
    }
    
    @objc func airDropShare() {
        let text = debugTextView.string
        guard let url = getTextFileURL(text: text) else {
            otherShare()
            return
        }
        
        let service = NSSharingService(named: .sendViaAirDrop)!
        let items: [NSURL] = [url as NSURL]
        if service.canPerform(withItems: items) {
          service.perform(withItems: items)
        } else {
            NSAlert.show("Cannot perform AirDrop!")
        }
    }
    
    @objc func otherShare() {
        var item: Any = debugTextView.string
        if let text = item as? String, let url = getTextFileURL(text: text) {
            item = url
        }
        let picker = NSSharingServicePicker(items: [item])
        picker.show(relativeTo: .zero, of: shareBtn, preferredEdge: .maxX)
    }
    
}
