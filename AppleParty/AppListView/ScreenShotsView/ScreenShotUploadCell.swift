//
//  ScreenShotUploadCell.swift
//  AppleParty
//
//  Created by HTC on 2022/2/25.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa
import Foundation


class ScreenShotDeleteCell: NSTableCellView {
    
    typealias CallFunc = (_ row: Int) -> Void
    var deleteCell: CallFunc?
    var row: Int = 0
    
    @IBOutlet weak var deleteBtn: NSButton!
    
    @IBAction func clickedDeleteBtn(_ sender: NSButton) {
        if let callBack = deleteCell {
            callBack(row)
        }
    }
}

class ScreenShotUploadCell: NSTableCellView {
    
    typealias CallBackHandler = (_ value: String, _ row: Int) -> Void
    var changeSortIndex: CallBackHandler?
    var changeVideoFrame: CallBackHandler?
    var row: Int = 0
    
    @IBOutlet weak var sortField: NSTextField!
    @IBOutlet weak var videoField: NSTextField!
    @IBOutlet weak var videoTitleField: NSTextField!
    
    @IBOutlet weak var cellTopConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sortField.delegate = self
        videoField.delegate = self
    }
    
    func updateData(sort: String, frame: String) {
        sortField.stringValue = sort
        videoField.stringValue = frame
    }
    
    func showVideoView(_ show: Bool) {
        videoField.isHidden = !show
        videoTitleField.isHidden = !show
        cellTopConstraint.constant = show ? 10.0 : 20.0
    }
    
}

extension ScreenShotUploadCell: NSTextFieldDelegate {
    /// 内容改变
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        let value = textField.stringValue
        if textField.tag == sortField.tag, let callBack = changeSortIndex {
            callBack(value, row)
        }
        
        if textField.tag == videoField.tag, let callBack = changeVideoFrame {
            callBack(value, row)
        }
    }
}
