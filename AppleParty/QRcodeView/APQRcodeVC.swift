//
//  APQRcodeVC.swift
//  AppleParty
//
//  Created by HTC on 2022/3/24.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APQRcodeVC: NSViewController {

    @IBOutlet weak var inputTextField: NSTextField!
    @IBOutlet weak var qrcodeSizeBtn: NSPopUpButton!
    @IBOutlet weak var createQrcodeBtn: NSButton!
    @IBOutlet weak var qrcodeImageView: NSImageView!
    @IBOutlet weak var copyQrcodeBtn: NSButton!
    @IBOutlet weak var saveQrcodeBtn: NSButton!
    @IBOutlet weak var shareQrcodeBtn: NSButton!
    @IBOutlet weak var shareQrcodeByAirDropBtn: NSButton!
    @IBOutlet weak var scanQrcodeBtn: NSButton!
    @IBOutlet weak var messageLbl: NSTextField!
    @IBOutlet weak var textScrollView: NSScrollView!
    @IBOutlet weak var textView: NSTextView!
    
    @IBAction func createQrcode(_ sender: Any) {
        let str = inputTextField!.stringValue
        if str.isEmpty {
            enableQrcode(false)
            statusMessage("")
            NSAlert.show("请输出需要生成二维码的文本！")
            return
        }
        
        let img = createQRImage(str, NSMakeSize(360, 360))
        qrcodeImageView.image = img
        enableQrcode(true)
        statusMessage("二维码生成成功")
    }
    
    @IBAction func copyQrcode(_ sender: Any) {
        let str = inputTextField!.stringValue
        if !str.isEmpty {
            let img = createQRImage(str, getImageSize())
            let pb = NSPasteboard.general
            pb.clearContents()
            if pb.writeObjects([img as NSPasteboardWriting]) {
                statusMessage("Copy QRCode to clipboard")
            } else {
                statusMessage("Failed to copy QRCode to clipboard")
            }
        }
    }
    
    
    @IBAction func saveQrcode(_ sender: Any) {
        let str = inputTextField!.stringValue
        if str.isEmpty {
            return statusMessage("请填写有效的文本内容！")
        }
        
        let savePanel = NSSavePanel()
        savePanel.title = "Save QRCode As File"
        savePanel.canCreateDirectories = true
        savePanel.allowedFileTypes = ["png"]
        savePanel.isExtensionHidden = false
        savePanel.nameFieldStringValue = getImgaeName() + ".png"
        savePanel.becomeKey()
        let result = savePanel.runModal()
        if (result == .OK && (savePanel.url) != nil) {
            let img = createQRImage(str, getImageSize())
            let imgRep = NSBitmapImageRep(data: img.tiffRepresentation!)
            let data = imgRep?.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
            try! data?.write(to: savePanel.url!)
            statusMessage("Save QRCode to \(savePanel.url!.absoluteString)")
        }
    }
    
    @IBAction func shareQrcode(_ sender: Any) {
        let str = inputTextField!.stringValue
        if str.isEmpty {
            return statusMessage("请填写有效的文本内容！")
        }
        
        let img = createQRImage(str, getImageSize())
        let picker = NSSharingServicePicker(items: [img])
        picker.delegate = self
        picker.show(relativeTo: .zero, of: sender as! NSView, preferredEdge: .maxX)
    }
    
    @IBAction func shareQrcodeByAirDrop(_ sender: Any) {
        let str = inputTextField!.stringValue
        if str.isEmpty {
            return statusMessage("请填写有效的文本内容！")
        }
        
        let img = createQRImage(str, getImageSize())
        let service = NSSharingService(named: .sendViaAirDrop)!
        let items: [NSImage] = [img]
        if service.canPerform(withItems: items) {
          service.delegate = self
          service.perform(withItems: items)
        } else {
            statusMessage("Cannot perform AirDrop!")
        }
    }
    
    @IBAction func scanQrcode(_ sender: Any) {
        enableQrcode(false)
        qrcodeImageView.isHidden = true
        textView.string = ""
        textScrollView.isHidden = false
        // scan QRCode
        let dict = scanQRCodeOnScreen() as! [String:Any]
        let data = dict["qrcode"] as! Array<String>
        if data.isEmpty {
            textView.string = "Not found valid QRCode of screen!"
            return
        }
        // output message
        appendToTextView("识别到二维码个数：\(data.count)\n", coreText: "\(data.count)")
        for (index, element) in data.enumerated() {
            let k = index + 1
            appendToTextView("\n第\(k)个二维码内容：\n【\n\(element)\n】\n", coreText: element)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        inputTextField.becomeFirstResponder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        inputTextField.delegate = self
        enableQrcode(false)
        qrcodeImageView.image = NSImage(named: "QRcode")
    }
    
    func enableQrcode(_ enable: Bool) {
        copyQrcodeBtn.isEnabled = enable
        saveQrcodeBtn.isEnabled = enable
        shareQrcodeBtn.isEnabled = enable
        shareQrcodeByAirDropBtn.isEnabled = enable
        textScrollView.isHidden = true
        qrcodeImageView.isHidden = false
        if !enable {
            statusMessage("")
            qrcodeImageView.image = NSImage(named: "QRcode")
        }
    }
    
    func statusMessage(_ msg: String) {
        messageLbl.stringValue = msg.count == 0 ? "" : "提示：\(msg)"
    }
    
    func getImageSize() -> NSSize {
        let wh = CGFloat(qrcodeSizeBtn?.selectedTag() ?? 500)
        let size = NSMakeSize(wh, wh)
        return size
    }
    
    func getImgaeName() -> String {
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH-mm-ss"
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        return "AppleParty_qrcode-" + dateString
    }
    
    func appendToTextView(_ text: String, coreText: String) {
        let attributes = [NSAttributedString.Key.foregroundColor: NSColor.labelColor]
        let secondAttributes = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.3211918473, green: 0.7199308276, blue: 1, alpha: 1)]
        let attr = NSMutableAttributedString.init(string: text, attributes: attributes)
        attr.addAttributes(secondAttributes, range: (text as NSString).range(of: coreText))
        textView.textStorage?.append(attr)
        textView.scrollRangeToVisible(NSMakeRange(textView.string.count, 0))
    }
}


extension APQRcodeVC: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
      let textField = obj.object as! NSTextField
        if textField.stringValue.isEmpty {
            enableQrcode(false)
        }
    }
}


extension APQRcodeVC: NSSharingServicePickerDelegate, NSSharingServiceDelegate {
    
    
}
