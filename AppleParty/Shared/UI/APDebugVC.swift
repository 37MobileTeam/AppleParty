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
    var debugLog: String = "" {
        didSet {
            uploadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func uploadData() {
        debugTextView.string = debugLog
        debugTextView.scrollRangeToVisible(NSMakeRange(debugTextView.string.count, 0))
    }
}
