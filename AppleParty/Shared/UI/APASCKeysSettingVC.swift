//
//  APASCKeysSettingVC.swift
//  AppleParty
//
//  Created by HTC on 2022/11/18.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APASCKeysSettingVC: NSViewController {

    // 模型
    var models = [AppStoreConnectKey]()
    // 回调当前选择的账号
    var updateCompletion: ((_ model: AppStoreConnectKey?) -> Void)?
    
    @IBOutlet weak var tableView: NSTableView!
    
    
    @IBAction func clickedAddBtn(_ sender: Any) {
        let vc = APASCKeysEditVC()
        vc.titleString = "新增 API 密钥"
        vc.updateCompletion = { [weak self] news in
            // 相同账号的只保留最新
            self?.models = self?.models.filter({ $0.aliasName != news.aliasName }) ?? []
            if news.isused {
                // 只能有一个是使用的账号，其它为否
                self?.models = self?.models.map({ sp in
                    var spp = sp
                    return spp.model(sp, false)
                }) ?? []
            }
            self?.models.append(news)
            self?.tableView.reloadData()
        }
        presentAsSheet(vc)
    }
    
    @IBAction func clickedSaveBtn(_ sender: Any) {
        
        guard models.isNotEmpty else {
            APHUD.hide(message: "密钥配置不能为空！", view: view, delayTime: 2)
            return
        }
        
        // 保存数据
        InfoCenter.shared.ascKeys = models
        
        // 回调当前选择的账号
        if let block = updateCompletion {
            let models = self.models.filter({ $0.isused == true })
            block(models.first)
        }
        dismiss(self)
    }
    
    @IBAction func clickedCancelBtn(_ sender: Any) {
        dismiss(self)
    }
    
    private lazy var editMenu: NSMenu = {
        let menu = NSMenu()
        let saveItem = NSMenuItem()
        saveItem.title = "修改"
        saveItem.target = self
        saveItem.action = #selector(tableViewEditItemClicked)
        menu.addItem(saveItem)
        let removeItem = NSMenuItem()
        removeItem.title = "删除"
        removeItem.target = self
        removeItem.action = #selector(tableViewDeleteItemClicked)
        menu.addItem(removeItem)
        return menu
    }()
    
    @objc private func tableViewEditItemClicked(_ sender: AnyObject) {
        let row = tableView.clickedRow
        guard row >= 0 else { return }
        
        let result = models
        let index = result.index(result.startIndex, offsetBy: row)
        let model = result[index]
        let vc = APASCKeysEditVC()
        vc.titleString = "修改 API 密钥"
        vc.spassword = model
        vc.updateCompletion = { [weak self] news in
            if news.isused {
                // 只能有一个是使用的账号，其它为否
                self?.models = self?.models.map({ sp in
                    var spp = sp
                    return spp.model(sp, false)
                }) ?? []
            }
            self?.models[index] = news
            self?.tableView.reloadData()
        }
        presentAsSheet(vc)
    }

    @objc private func tableViewDeleteItemClicked(_ sender: AnyObject) {
        let row = tableView.clickedRow
        guard row >= 0 else { return }

        let result = models
        let index = result.index(result.startIndex, offsetBy: row)
        models.remove(at: index)
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        
        tableView.menu = editMenu
        tableView.delegate = self
        tableView.dataSource = self
        
        models = InfoCenter.shared.ascKeys
        tableView.reloadData()
    }
}


// MARK: NSTableViewDataSource && NSTableViewDelegate
extension APASCKeysSettingVC: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return models.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30.0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let result = models
        let index = result.index(result.startIndex, offsetBy: row)
        let model = result[index]
        let identifier = tableColumn!.identifier
        let identifierString = identifier.rawValue
        
        if identifierString == "AccountCell" {
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
            cellView.textField!.stringValue = model.aliasName
            return cellView
        }
        else if identifierString == "IssuerIDCell" {
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
            cellView.textField!.stringValue = model.issuerID
            return cellView
        }
        else if identifierString == "currentUseCell" {
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
            cellView.textField!.stringValue = model.isused ? "✓" : "-"
            return cellView
        }
        else if identifierString == "PrivateKeyID" {
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
            cellView.textField!.stringValue = model.privateKeyID
            return cellView
        }
        else if identifierString == "PrivateKey" {
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
            cellView.textField!.stringValue = model.privateKey
            return cellView
        }
        else {
            print("unhandled colum id: \(identifierString)")
        }
        return nil
    }

    
    // MARK: 是否可以选中单元格
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        return true
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let table = notification.object as! NSTableView
        table.deselectRow(table.selectedRow)
    }
    
}

