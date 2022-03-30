//
//  APInAppPurchseCell.swift
//  AppleParty
//
//  Created by HTC on 2022/3/28.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APInAppPurchseCell: NSTableCellView {
    
    
}

class ImageViewCell: NSTableCellView {

    @IBOutlet weak var imgSel: NSImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

class UploadCell: NSTableCellView {

    var row: Int = 0
    
    @IBOutlet weak var imgSel: NSImageView!
    @IBOutlet weak var dragView: DragView!
    @IBOutlet weak var dragBox: NSView!
    
    typealias CallBackFunc = (_ path: String, _ row: Int) -> Void
    var callBackFunc: CallBackFunc?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dragView.delegate = self
    }
}

extension UploadCell: DragViewDelegate {
    func dragView(_ path: String?) {
        if let path = path {
            debugPrint(path)
            imgSel.image = NSImage(contentsOfFile: path)
            if let callBackFunc = callBackFunc {
                callBackFunc(path, row)
            }
        } else {
            imgSel.image = nil
        }
    }
}


enum ColumnIdetifier: String {
    case id
    case productID
    case productName
    case priceLevel
    case appleid
    case price
    case type
    case state
    
    // list
    case productPds
    case level
    case status
    case screenshot
    case language
    case upload
    case picname
    
    var columnValue: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(rawValue: self.rawValue+"Column")
    }
    var cellValue: NSUserInterfaceItemIdentifier {
        return NSUserInterfaceItemIdentifier(rawValue: self.rawValue+"Cell")
    }
}

extension NSUserInterfaceItemIdentifier {
    func stringValue() -> String {
        switch self {
        case ColumnIdetifier.id.columnValue:
            return ColumnIdetifier.id.rawValue
        case ColumnIdetifier.productID.columnValue:
            return ColumnIdetifier.productID.rawValue
        case ColumnIdetifier.productName.columnValue:
            return ColumnIdetifier.productName.rawValue
        case ColumnIdetifier.price.columnValue:
            return ColumnIdetifier.price.rawValue
        case ColumnIdetifier.type.columnValue:
            return ColumnIdetifier.type.rawValue
        case ColumnIdetifier.state.columnValue:
            return ColumnIdetifier.state.rawValue
        case ColumnIdetifier.productPds.columnValue:
            return ColumnIdetifier.productPds.rawValue
        case ColumnIdetifier.level.columnValue:
            return ColumnIdetifier.level.rawValue
        case ColumnIdetifier.status.columnValue:
            return ColumnIdetifier.status.rawValue
        case ColumnIdetifier.appleid.columnValue:
            return ColumnIdetifier.appleid.rawValue
        case ColumnIdetifier.priceLevel.columnValue:
            return ColumnIdetifier.priceLevel.rawValue
        case ColumnIdetifier.screenshot.columnValue:
            return ColumnIdetifier.screenshot.rawValue
        case ColumnIdetifier.picname.columnValue:
            return ColumnIdetifier.picname.rawValue
        case ColumnIdetifier.upload.columnValue:
            return ColumnIdetifier.upload.rawValue
        case ColumnIdetifier.language.columnValue:
            return ColumnIdetifier.language.rawValue
        default:
            return "none"
        }
    }
    
    func enumValue() -> NSUserInterfaceItemIdentifier {
        switch self {
        case ColumnIdetifier.id.columnValue:
            return ColumnIdetifier.id.cellValue
        case ColumnIdetifier.productID.columnValue:
            return ColumnIdetifier.productID.cellValue
        case ColumnIdetifier.productName.columnValue:
            return ColumnIdetifier.productName.cellValue
        case ColumnIdetifier.price.columnValue:
            return ColumnIdetifier.price.cellValue
        case ColumnIdetifier.type.columnValue:
            return ColumnIdetifier.type.cellValue
        case ColumnIdetifier.state.columnValue:
            return ColumnIdetifier.state.cellValue
        case ColumnIdetifier.productPds.columnValue:
            return ColumnIdetifier.productPds.cellValue
        case ColumnIdetifier.level.columnValue:
            return ColumnIdetifier.level.cellValue
        case ColumnIdetifier.status.columnValue:
            return ColumnIdetifier.status.cellValue
        case ColumnIdetifier.appleid.columnValue:
            return ColumnIdetifier.appleid.cellValue
        case ColumnIdetifier.priceLevel.columnValue:
            return ColumnIdetifier.priceLevel.cellValue
        case ColumnIdetifier.screenshot.columnValue:
            return ColumnIdetifier.screenshot.cellValue
        case ColumnIdetifier.picname.columnValue:
            return ColumnIdetifier.picname.cellValue
        case ColumnIdetifier.upload.columnValue:
            return ColumnIdetifier.upload.cellValue
        case ColumnIdetifier.language.columnValue:
            return ColumnIdetifier.language.cellValue
        default:
            return NSUserInterfaceItemIdentifier(rawValue: "none")
        }
    }
}
