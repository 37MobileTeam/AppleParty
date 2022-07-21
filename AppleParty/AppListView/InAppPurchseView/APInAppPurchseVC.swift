//
//  APInAppPurchseVC.swift
//  AppleParty
//
//  Created by HTC on 2022/3/28.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APInAppPurchseVC: NSViewController {
    
    public var currentApp: App? {
        didSet {
            fetchIAPs()
            appNameView.stringValue = currentApp?.appName ?? ""
        }
    }
    
    var iapList: [IAPList.IAP] = []
    
    @IBOutlet weak var outputIAPListBtn: NSButton!
    @IBOutlet weak var appNameView: NSTextField!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.outlineView.delegate = self
        self.outlineView.dataSource = self
        self.outlineView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        self.outlineView.selectionHighlightStyle = .none
        self.outlineView.allowsMultipleSelection = true
        self.outlineView.sizeToFit()
    }
    
    @IBAction func reloadIAPs(_ sender: Any) {
        fetchIAPs()
    }
    
    @IBAction func importExcel(_ sender: Any) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.beginSheetModal(for: self.view.window!) { [self] (modalResponse: NSApplication.ModalResponse) in
            if  modalResponse == .OK, let filePath = openPanel.url {
                handelExcel(filePath)
            }
        }
    }
    
    
    @IBAction func outputExcel(_ sender: Any) {
        
        guard iapList.count > 0 else {
            NSAlert.show("当前商品为空~")
            return
        }
        
        // 创建格式
        var iaps = "productId, 商品名称, 价格等级, 价格(RMB), AppleID, 商品类型, 状态, 送审图片\n"
        let separator = "\",\""
        iaps += iapList.map { item -> String in
            return "\"" + item.vendorId + separator + item.referenceName + separator + item.tierStem + separator + levelChargeMoney(item.tierStem) + separator + item.adamId
            + separator + item.addOnType.CNValue() + separator + item.iTunesConnectStatus.statusValue.0 + separator + (item.reviewScreenshot?.url ?? "-") + "\""
        }.joined(separator: "\n")
        
        // 保存文件
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmm_"
        let currentDate = dateFormatter.string(from: Date())
        let mySave = NSSavePanel()
        mySave.allowedFileTypes = ["csv"]
        mySave.nameFieldStringValue = "内购列表" + currentDate + currentApp!.appName.replacingOccurrences(of: " ", with: "-")
        mySave.begin { (result) -> Void in
            if result == .OK {
                let filePath = mySave.url
                do {
                    // 含有中文，excel在打开CSV文件时默认用ASNI打开，无BOM头的unicode文件会出现乱码
                    var data = Data([0xEF, 0xBB, 0xBF])
                    data.append(contentsOf: iaps.data(using: .utf8) ?? Data())
                    try data.write(to: filePath!)
                } catch {
                    NSAlert.show("导出失败：\(error.localizedDescription)")
                }
            }
        }
    }
    
    @IBAction func outputProductID(_ sender: Any) {
        let mainStoryboard = NSStoryboard(name: "InAppPurchseView", bundle: Bundle(for: self.classForCoder))
        let outputVC = mainStoryboard.instantiateController(withIdentifier: "OutputExcelVCID") as? OutputExcelVC
        outputVC?.iapList = iapList
        presentAsSheet(outputVC!)
    }
    
    @IBAction func downloadExcel(_ sender: Any) {
        XMLManager.copySimpleExel()
    }
}


// MARK: - 网络请求
extension APInAppPurchseVC {
    
    // 请求商品列表
    func fetchIAPs() {
        APClient.iaps(appid: currentApp!.appId).request(showLoading: true, inView: self.view) { [weak self] result, response, error in
            guard let err = error else {
                guard let app = self?.currentApp else { return } //请求过程关闭页面可能导致为空
                let iapL = IAPList(body:result, app: app)
                self?.iapList = iapL.iapList
                self?.outlineView.reloadData()
                self?.updateRowInfo()
                return
            }
            APHUD.hide(message: err.localizedDescription, view: self?.view ?? currentView())
        }
    }
    
    func updateRowInfo() {
        guard self.iapList.count > 0 else {
            return
        }
        
        outputIAPListBtn.isEnabled = false
        let group = DispatchGroup()
        for i in 0..<self.iapList.count {
            group.enter()
            APClient.iapDetail(appid: currentApp!.appId, iapid: iapList[i].adamId).request { [weak self] result, response, error in
                group.leave()
                guard let err = error else {
                    if var newModel = self?.iapList[i] {
                        newModel.updateDetail(body: result)
                        self?.iapList[i] = newModel
                        self?.outlineView.reloadData()
                    }
                    return
                }
                APHUD.hide(message: err.localizedDescription, view: self?.view ?? currentView())
            }
        }
        group.notify(queue: .main) {
            self.outputIAPListBtn.isEnabled = true
            self.outlineView.reloadData()
        }
    }
    
}

// MARK: - 内部方法
extension APInAppPurchseVC {
    
    
    func handelExcel(_ excelFilePath: URL) {
        // [pris, prods, names, levels, dps, types, scrs]
        let xlsx = XLSXParser.parser(filePath: excelFilePath.path)
        var pris = xlsx[0]
        var ids = xlsx[1]
        var names = xlsx[2]
        var levs = xlsx[3]
        var dps = xlsx[4]
        var types = xlsx[5]
        var scrs = xlsx[6]
        var langsOrigianl = xlsx[7]
        
        // 检查行数
        guard ids.count == names.count, pris.count == levs.count, dps.count == types.count, types.count == ids.count, names.count == langsOrigianl.count else {
            NSAlert.show("表格行数不一致!")
            return
        }
        
        //忽略空行
        let rowNum = ids.count
        var index = 0
        for _ in 0..<rowNum {
            if pris[index].isEmpty,ids[index].isEmpty,names[index].isEmpty,levs[index].isEmpty,dps[index].isEmpty,types[index].isEmpty,scrs[index].isEmpty,langsOrigianl[index].isEmpty {
                pris.remove(at: index)
                ids.remove(at: index)
                names.remove(at: index)
                levs.remove(at: index)
                dps.remove(at: index)
                types.remove(at: index)
                scrs.remove(at: index)
                langsOrigianl.remove(at: index)
            }
            else {
                index += 1
            }
        }
        
        // 如果没有填写，默认用简中
        let langs = langsOrigianl.count > 0 ? langsOrigianl.map { $0.count > 0 ? $0 : "zh-Hans" } : [String](repeating: "zh-Hans", count: ids.count)
        
        // TODO: 检查字符长度要求
        if ids.count == 1, ids.first == "" {
            NSAlert.show("数据不能为空！")
            return
        }
        
        // 【产品 ID】 可以由字母、数字、下划线（_）和句点（.）构成。 2 ~ 255 个字符）
        if ids.contains(where: { $0.count < 2 || $0.count > 255 }) {
            let msg = ids.filter { $0.count < 2 || $0.count > 255 }
            NSAlert.show("商品id长度为：2~255 字符！详细错误：\(msg)")
            return
        }
        
        // 商品名称（必填） 2~30个字符
        if names.contains(where: { $0.count < 2 || $0.count > 30 }) {
            let msg = names.filter { $0.count < 2 || $0.count > 30 }
            NSAlert.show("商品名称长度为：2~30 字符！详细错误：\(msg)")
            return
        }
        
        // 商品描述（必填） 10~45个字符
        if dps.contains(where: { $0.count < 10 || $0.count > 45 }) {
            let msg = dps.filter { $0.count < 10 || $0.count > 45 }
            NSAlert.show("商品描述长度为：10~45 字符！详细错误：\(msg)")
            return
        }
        
        //【屏幕快照】5 ~ 255 个字符，暂时非强制
        
        // 检查品项是否已经存在
        if iapList.isNotEmpty {
            let iaps = iapList.map { $0.vendorId }
            let warns = ids.filter { iaps.contains($0) }
            if warns.isNotEmpty {
                NSAlert.show("‼️警告：已经存在相同商品id的品项！请检查：\(warns)。\n⚠️提示：如果继续上传，将会覆盖已有品项的信息！")
            }
        }

        // 生成模型
        var itms = XMLModel()
        var isAllScreentshotEmpty = true
        for i in 0..<ids.count {
            var model = In_App_Purchase()
            model.product_id = ids[i]
            model.reference_name = names[i]
            model.type = chargeType(ch: types[i])
            model.wholesale_price_tier = chargeLevel(level: levs[i])
            model.inputPrice = pris[i]
            model.description = dps[i]
            model.title = names[i]
            model.review_notes = dps[i]
            if scrs.count > i && scrs[i].isNotEmpty {
                model.file_name = scrs[i]
                isAllScreentshotEmpty = false
            }else {
                model.file_name = default_screenshot_file_name
            }
            model.lang = langs[i]
            itms.iaps.append(model)
        }
        
        let sb = NSStoryboard(name: "InAppPurchseView", bundle: Bundle(for: self.classForCoder))
        let wc = sb.instantiateController(withIdentifier: "InputExcelList") as? NSWindowController
        let vc = wc?.contentViewController as? InputExcelListVC
        vc?.currentApp = currentApp
        vc?.waitUploadModel = itms
        vc?.isAllScreentshotEmpty = isAllScreentshotEmpty
        vc?.checkPris = pris
        vc?.screenshots = itms.iaps.map({ $0.file_name })
        wc?.showWindow(self)
    }
    
    
    func setModels(models: [IAPList.IAP]) {
        iapList = models
        outlineView.reloadData()
        outlineView.sizeToFit()
        updateRowInfo()
    }
    
}


// MARK: - NSOutlineViewDelegate
extension APInAppPurchseVC: NSOutlineViewDelegate, NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        if let item = item as? IAPList.IAP {
            switch tableColumn?.identifier.enumValue() {
            case ColumnIdetifier.id.cellValue:
                let cell = outlineView.makeView(withIdentifier: ColumnIdetifier.id.cellValue, owner: self) as? NSTableCellView
                cell?.textField?.stringValue = String(item.curid)
                return cell
            case ColumnIdetifier.productID.cellValue:
                let cell = outlineView.makeView(withIdentifier: ColumnIdetifier.productID.cellValue, owner: self) as? NSTableCellView
                cell?.textField?.stringValue = item.vendorId
                return cell
            case ColumnIdetifier.productName.cellValue:
                let cell = outlineView.makeView(withIdentifier: ColumnIdetifier.productName.cellValue, owner: self) as? NSTableCellView
                cell?.textField?.stringValue = item.referenceName
                return cell
            case ColumnIdetifier.price.cellValue:
                let cell = outlineView.makeView(withIdentifier: ColumnIdetifier.price.cellValue, owner: self) as? NSTableCellView
                cell?.textField?.stringValue = levelChargeMoney(item.tierStem)
                return cell
            case ColumnIdetifier.priceLevel.cellValue:
                let cell = outlineView.makeView(withIdentifier: ColumnIdetifier.priceLevel.cellValue, owner: self) as? NSTableCellView
                cell?.textField?.stringValue = item.tierStem
                return cell
            case ColumnIdetifier.appleid.cellValue:
                let cell = outlineView.makeView(withIdentifier: ColumnIdetifier.appleid.cellValue, owner: self) as? NSTableCellView
                cell?.textField?.stringValue = item.adamId
                return cell
            case ColumnIdetifier.type.cellValue:
                let cell = outlineView.makeView(withIdentifier: ColumnIdetifier.type.cellValue, owner: self) as? NSTableCellView
                cell?.textField?.stringValue = item.addOnType.CNValue()
                return cell
            case ColumnIdetifier.state.cellValue:
                let cell = outlineView.makeView(withIdentifier: ColumnIdetifier.state.cellValue, owner: self) as? NSTableCellView
                cell?.textField?.stringValue = item.iTunesConnectStatus.statusValue.0
                cell?.textField?.textColor = item.iTunesConnectStatus.statusValue.1
                return cell
            default:
                return nil
            }
        }else if let item = item as? String {
            switch tableColumn?.identifier.enumValue() {
            case ColumnIdetifier.productID.cellValue:
                let imgView = NSImageView()
                imgView.showWebImage(item)
                return imgView
            default:
                return nil
            }
        }else {
            return nil
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item is IAPList.IAP {
            return 1
        }else {
            return iapList.count
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is IAPList.IAP {
            return true
        }else {
            return false
        }
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let item = item as? IAPList.IAP {
            return item.reviewScreenshot?.thumbNailUrl as Any
        }
        return iapList[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is IAPList.IAP {
            return 35
        }else {
            return 100
        }
    }
}
