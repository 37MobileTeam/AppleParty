//
//  APSPasswordSettingVC.swift
//  AppleParty
//
//  Created by HTC on 2022/5/18.
//  Copyright © 2022 37 Mobile models. All rights reserved.
//

import Cocoa

class APSPasswordSettingVC: NSViewController {

    // 模型
    var models = [SPassword]()
    // 回调当前选择的账号
    var updateCompletion: ((_ model: SPassword?) -> Void)?
    
    @IBOutlet weak var tableView: NSTableView!
    
    
    @IBAction func clickedAddBtn(_ sender: Any) {
        let vc = APSPasswordEditVC()
        vc.titleString = "新增专用密码"
        vc.updateCompletion = { [weak self] news in
            // 相同账号的只保留最新
            self?.models = self?.models.filter({ $0.account != news.account }) ?? []
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
            APHUD.hide(message: "账号邮箱和专用密码不能为空！", view: view, delayTime: 2)
            return
        }
        
        // 保存数据
        UserCenter.shared.secondaryPasswordList = models
        
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
        let vc = APSPasswordEditVC()
        vc.titleString = "新增专用密码"
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
        
        models = UserCenter.shared.secondaryPasswordList
        tableView.reloadData()
    }
}


// MARK: NSTableViewDataSource && NSTableViewDelegate
extension APSPasswordSettingVC: NSTableViewDataSource, NSTableViewDelegate {
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
            cellView.textField!.stringValue = model.account
            return cellView
        }
        else if identifierString == "PasswordCell" {
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
            cellView.textField!.stringValue = model.password
            return cellView
        }
        else if identifierString == "currentUseCell" {
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self) as! NSTableCellView
            cellView.textField!.stringValue = model.isused ? "✓" : "-"
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
