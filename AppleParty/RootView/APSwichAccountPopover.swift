//
//  APSwichAccountPopover.swift
//  AppleParty
//
//  Created by HTC on 2022/3/18.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APSwichAccountPopover: NSViewController {
    
    public var accounts = [Provider]()
    public var selectHandle: ((_ row: Int) -> Void)?
    
    @IBOutlet weak var tableView: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func cliedCancelBtn(_ sender: Any) {
        closeView()
    }
    
    func closeView() {
        guard let window = view.window, let parent = window.sheetParent
        else { return }
        parent.endSheet(window)
    }
    
}

extension APSwichAccountPopover: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return accounts.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableColumn?.identifier == NSUserInterfaceItemIdentifier(rawValue: "nameColumn") {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = accounts[row].name
            return cellView
        }
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification){
        let tableView = notification.object as! NSTableView
        let clickedRow = tableView.selectedRow
        guard clickedRow >= 0 else {
            return
        }
        tableView.deselectRow(clickedRow)
        if let selectFunc = selectHandle {
            selectFunc(clickedRow)
        }
        closeView()
    }
}
