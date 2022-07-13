//
//  APAppListCell.swift
//  AppleParty
//
//  Created by HTC on 2022/3/17.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APAppListCell: NSCollectionViewItem {

    public var purchseHandle: ((_ app: App) -> Void)?
    public var screenshotHandle: ((_ app: App) -> Void)?
    
    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var nameView: NSTextField!
    
    private var app: App?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameView.maximumNumberOfLines = 2
        imgView.wantsLayer = true
        imgView.layer?.cornerRadius = 22
        imgView.layer?.masksToBounds = true
    }
    
    @IBAction func clickedPurchseItem(_ sender: Any) {
        purchseHandle?(app!)
    }
    
    @IBAction func clickedScreenshotItem(_ sender: Any) {
        screenshotHandle?(app!)
    }
    
    func configure(app: App) {
        self.app = app
        nameView.stringValue = app.appName
        imgView?.showWebImage(app.iconUrl)
    }
    
    
}
