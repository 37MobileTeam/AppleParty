//
//  OutputExcelVC.swift
//  AppleParty
//
//  Created by 易承 on 2020/12/23.
//

import Cocoa

class OutputExcelVC: NSViewController, NSTextViewDelegate {
    
    @IBOutlet var inputText: NSTextView!
    @IBOutlet weak var outputView: NSScrollView!
    @IBOutlet var outputText: NSTextView!
    
    @IBOutlet weak var inputCount: NSTextField!
    @IBOutlet weak var outputCount: NSTextField!
    
    var inputs = [String]()
    var outputs = [String]()
    
    var iapList: [IAPList.IAP] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inputText.delegate = self
    }
    
    @IBAction func close(_ sender: Any) {
        dismiss(self)
    }
    
    @IBAction func commit(_ sender: Any) {
        outputs.removeAll()
        for i in 0..<inputs.count {
            for iap in iapList {
                if inputs[i] == iap.vendorId {
                    outputs.append(iap.adamId)
                    break
                }
            }
            // 没有找到对应的商品id
            if outputs.count != i+1 {
                outputs.append("")
            }
        }
        outputView.isHidden = false
        outputText.string = outputs.joined(separator: "\n")
    }
    
    func textViewDidChangeSelection(_ notification: Notification) {
        inputs = inputText.string.components(separatedBy: CharacterSet(["\r", "\n"]))
        inputs = inputs.filter { $0.count > 0 }
        inputCount.stringValue = String(inputs.count)+"/100"
    }
    
    func checkCount() -> Bool {
        guard inputs.count == outputs.count else {
            inputCount.textColor = NSColor.red
            outputCount.textColor = NSColor.red
            return false
        }
        inputCount.textColor = NSColor.lightGray
        outputCount.textColor = NSColor.lightGray
        return true
    }
}
