//
//  APRootCollectionCell.swift
//  AppleParty
//
//  Created by HTC on 2022/3/14.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APRootCollectionCell: NSCollectionViewItem {

    @IBOutlet weak var imgView: NSImageView!
    @IBOutlet weak var nameView: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func configure(name: String, icon: String) {
        nameView.stringValue = name
        imgView?.image = NSImage(named: icon)
    }
    
}
