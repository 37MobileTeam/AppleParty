//
//  APPasswordVC.swift
//  AppleParty
//
//  Created by HTC on 2022/3/21.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APPasswordVC: NSViewController {

    @IBOutlet weak var password: NSTextField!
    
    typealias CallBackFunc = (_ password: String) -> Void
    var callBackFunc: CallBackFunc?
    var cancelBtnFunc: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func enter(_ sender: Any) {
        if let callBackFunc = callBackFunc {
            dismiss(self)
            callBackFunc(password.stringValue)
        }
    }
    
    @IBAction func clickedCancelBtn(_ sender: Any) {
        dismiss(self)
        if let cancelBtnFunc = cancelBtnFunc {
            cancelBtnFunc()
        }
    }
    
}
