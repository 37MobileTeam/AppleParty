//
//  APVerifyReceiptVC.swift
//  AppleParty
//
//  Created by HTC on 2022/6/1.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APVerifyReceiptVC: NSViewController {

    @IBOutlet weak var sharedSecretField: NSTextField!
    @IBOutlet weak var apiTypeMatrix: NSMatrix!
    @IBOutlet weak var receiptTextView: NSTextView!
    @IBOutlet weak var responseTextView: NSTextView!
    @IBOutlet weak var verifyButton: NSButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func clickedVerifyButtion(_ sender: Any) {
        
        let receiptString = receiptTextView.string
        if receiptString.isEmpty {
            APHUD.hide(message: "请填写 receipt base64 字符串~", delayTime: 1)
            return
        }
        
        responseTextView.string = ""
        APHUD.show(message: "请求中...")
        
        let sharedSecretString = sharedSecretField.stringValue
        var apiUrl = ""
        let apiType = apiTypeMatrix.selectedRow
        if apiType == 0 {
            apiUrl = "https://sandbox.itunes.apple.com/verifyReceipt"
        }
        else if (apiType == 1) {
            apiUrl = "https://buy.itunes.apple.com/verifyReceipt"
        }
        
        // unused : exclude-old-transactions
        var json: [String: Any] = ["receipt-data": receiptString]
        if !sharedSecretString.isEmpty {
            json["password"] = sharedSecretString
        }
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        // create post request
        let url = URL(string: apiUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            APHUD.hide()
            guard let data = data, error == nil else {
                let msg = error?.localizedDescription ?? "未知错误"
                APHUD.hide(message: msg, delayTime: 1)
                print(msg)
                return
            }
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            if let responseJSON = responseJSON as? [String: Any] {
                DispatchQueue.main.async {
                    self?.responseTextView.string = String(format: "\(responseJSON)")
                }
            } else {
                APHUD.hide(message: "数据解析错误~", delayTime: 1)
            }
        }

        task.resume()
    
    }
    
}
