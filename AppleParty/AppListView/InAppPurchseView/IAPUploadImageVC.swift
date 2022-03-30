//
//  UploadVC.swift
//  AppleParty
//
//  Created by 易承 on 2021/6/3.
//

import AppKit
import Foundation

class IAPUploadImageVC: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var cancelBtm: NSButton!
    @IBOutlet weak var submitBtm: NSButton!
    @IBOutlet weak var tipLb: NSTextField!
    var picnames = [String]()
    var resultPaths = [String: String]()
    
    typealias CallBackFunc = (_ paths: [String: String]) -> Void
    var callBackFunc: CallBackFunc?
    
    fileprivate lazy var fileTypes: [String] = {
        return  ["jpg", "jpeg", "png"]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tipLb.stringValue = "需要上传\(picnames.count)张图片"
    }
    
    @IBAction func clickedBatchUploadBtn(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = true
        openPanel.allowedFileTypes = fileTypes
        openPanel.beginSheetModal(for: self.view.window!) { (modalResponse: NSApplication.ModalResponse) in
            if  modalResponse == .OK {
                openPanel.urls.forEach { url in
                    let picname = url.lastPathComponent
                    debugPrint(picname)
                    if self.picnames.contains(picname) {
                        debugPrint("contains")
                        self.resultPaths[picname] = url.path
                    }
                }
                self.tableView.reloadData()
            }
        }
    }
    
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(self)
    }
    
    @IBAction func submit(_ sender: Any) {
        guard picnames.count == resultPaths.keys.count else {
            APHUD.hide(message: "必须图片数量不正确！", view: self.view)
            return
        }
        dismiss(self)
        if let callBackFunc = callBackFunc {
            callBackFunc(resultPaths)
        }
    }
}

extension IAPUploadImageVC: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return picnames.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableColumn?.identifier.enumValue() {
        case ColumnIdetifier.picname.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.picname.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = picnames[row]
            return cell
        case ColumnIdetifier.upload.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.upload.cellValue, owner: self) as? UploadCell
            cell?.row = row
            cell?.dragView(resultPaths[picnames[row]])
            cell?.callBackFunc = { path,crow in
                self.resultPaths[self.picnames[crow]] = path
            }
            return cell
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        100
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}
