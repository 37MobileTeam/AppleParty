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
    private var countryCode = ""
    private var checkPrice = [String: String]()
    
    @IBOutlet weak var pricePopupBtn: NSPopUpButton!
    @IBOutlet weak var outputIAPListBtn: NSButton!
    @IBOutlet weak var appNameView: NSTextField!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clickedPriceSelectPopupBtn(pricePopupBtn)
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
        var iaps = "productId, 商品名称, 价格等级, 价格(\(countryCode)), AppleID, 商品类型, 状态, 送审图片\n"
        let separator = "\",\""
        iaps += iapList.map { item -> String in
            return "\"" + item.vendorId + separator + item.referenceName + separator + item.priceTier + separator + (checkPrice[item.priceTier] ?? "-") + separator + item.adamId
            + separator + item.addOnType.CNValue() + separator + item.iTunesConnectStatus.statusValue.0 + separator + item.reviewScreenshot + "\""
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
    
    
    @IBAction func clickedPriceSelectPopupBtn(_ sender: NSPopUpButton) {
        
        var countryCode = "CN"
        switch sender.selectedTag() {
        case 1:
            countryCode = "CN"
        case 2:
            countryCode = "US"
        case 3:
            countryCode = "KR"
        case 4:
            countryCode = "JP"
        case 5:
            countryCode = "HK"
        case 6:
            countryCode = "TW"
        case 7:
            countryCode = "GB"
        case 8:
            countryCode = "DE"
        default: break
        }
        self.countryCode = countryCode
        self.checkPrice = PriceTierParser.priceTiers(countryCode)
        self.outlineView.reloadData()
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
            let iapid = iapList[i].adamId
            // 商品详细
            APClient.inAppPurchaseDetail(iapid: iapid).request { [weak self] result, response, error in
                group.leave()
                guard let err = error else {
                    if var newModel = self?.iapList[i] {
                        newModel.updateDetail(body: result)
                        self?.iapList[i] = newModel
                        self?.outlineView.reloadData()
                        group.enter()
                        // 商品价格
                        APClient.inAppPurchasePrices(iapid: iapid).request { [weak self] result, response, error in
                            group.leave()
                            guard let err = error else {
                                if var newModel = self?.iapList[i] {
                                    newModel.updatePrices(body: result)
                                    self?.iapList[i] = newModel
                                    self?.outlineView.reloadData()
                                }
                                return
                            }
                            APHUD.hide(message: err.localizedDescription, view: self?.view ?? currentView())
                        }
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
        let iaps = IAPExcelParser.parser(excelFilePath)
        
        // 检查内购品项是否后台已经创建过
        if iapList.isNotEmpty {
            let pids = iaps.map { $0.productId }
            let iaps = iapList.map { $0.vendorId }
            let warns = pids.filter { iaps.contains($0) }
            if warns.isNotEmpty {
                NSAlert.show("‼️警告：已经存在相同商品id的品项！请检查：\(warns)。\n⚠️提示：如果继续上传，将会覆盖已有品项的信息！")
            }
        }
        
        let sb = NSStoryboard(name: "InAppPurchseView", bundle: Bundle(for: self.classForCoder))
        let wc = sb.instantiateController(withIdentifier: "InputExcelList") as? NSWindowController
        let vc = wc?.contentViewController as? APUploadIAPListVC
        vc?.currentApp = currentApp
        vc?.iaps = iaps
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
                cell?.textField?.stringValue =  checkPrice[item.priceTier] ?? "-"
                return cell
            case ColumnIdetifier.priceLevel.cellValue:
                let cell = outlineView.makeView(withIdentifier: ColumnIdetifier.priceLevel.cellValue, owner: self) as? NSTableCellView
                cell?.textField?.stringValue = item.priceTier
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
            return item.reviewScreenshot as Any
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
