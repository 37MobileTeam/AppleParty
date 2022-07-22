//
//  InputTableListVC.swift
//  AppleParty
//
//  Created by 易承 on 2020/12/15.
//

import Cocoa

class InputExcelListVC: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var enterBtn: NSButton!
    
    public var currentApp: App? {
        didSet {
            setupUI()
            fetchAppInfo()
        }
    }
    public var waitUploadModel = XMLModel() {
        didSet {
            self.tableView.reloadData()
        }
    }
    public var isAllScreentshotEmpty = false
    private var appInfo: AppInfo?
    
    var checkPris = [String]()
    var screenshots = [String]()
    var ssPaths = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        self.tableView.selectionHighlightStyle = .none
        self.tableView.sizeToFit()
        self.tableView.reloadData()
        
        if !isAllScreentshotEmpty {
            //showUploadView()
        }
    }
    
    func setupUI() {
        self.view.window?.title = "批量内购买项目上传 - " + (currentApp?.appName ?? "")
        self.tableView.reloadData()
    }
    
    func showUploadView() {
        // 不能同时 present 出来
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let mainStoryboard = NSStoryboard(name: "InAppPurchseView", bundle: Bundle(for: self.classForCoder))
            let upVC = mainStoryboard.instantiateController(withIdentifier: "IAPUploadVCID") as? IAPUploadImageVC
            let ss = self.screenshots.enumerated().filter { (index,value) -> Bool in
                return self.screenshots.firstIndex(of: value) == index && value != default_screenshot_file_name
            }.map { $0.element }
            upVC?.picnames = ss
            upVC?.callBackFunc = { paths in
                self.ssPaths = paths
                self.tableView.reloadData()
            }
            self.presentAsSheet(upVC!)
        }
    }
    
    
    @IBAction func clickedUploadShotBtn(_ sender: Any) {
        showUploadView()
    }
    
    //点击右下角”设置特殊密码“
    @IBAction func clickedSPasswordBtn(_ sender: Any) {
        let sb = NSStoryboard(name: "APPasswordVC", bundle: Bundle(for: self.classForCoder))
        let pwdVC = sb.instantiateController(withIdentifier: "APPasswordVC") as? APPasswordVC
        pwdVC?.callBackFunc = { pwd in
            UserCenter.shared.developerKey = pwd
        }
        presentAsSheet(pwdVC!)
    }
    
    @IBAction func createIAP(_ sender: Any) {
        guard let appid = currentApp?.appId else {
            APHUD.hide(message: "当前 App 的 appleid 为空！", delayTime: 1)
            return
        }
        
        guard let info = appInfo else {
            fetchAppInfo()
            APHUD.hide(message: "加载数据异常，请刷新后重试~")
            return
        }
        
        var isPassImg = true
        for i in 0..<waitUploadModel.iaps.count {
            let model = waitUploadModel.iaps[i]
            let imgPath = ssPaths[model.file_name] ?? ""
            if model.file_name != default_screenshot_file_name, imgPath.isEmpty {
                isPassImg = false
                break
            }
        }
        
        guard isPassImg else {
            APHUD.hide(message: "还有截图没有上传，请检查~", delayTime: 1)
            return
        }
        
        // 更新必要参数
        waitUploadModel.vendor_id = info.sku
        
        // 先删除旧的文档
        XMLManager.deleteITMS(XMLManager.getITMSPath(appid))
        // 计算截图的大小和 md5
        reductPicSizeAndMD5()
        // 通过itms批量生成内购
        waitUploadModel.createIAP(directoryPath: XMLManager.getITMSPath(appid))
        
        enterBtn.isEnabled = false
        APHUD.show(message: "上传中", view: self.view)
        let uploadIAPs: ((String) -> Void) = { [weak self] pwd in
            DispatchQueue.global(qos: .userInitiated).async {
                let result = XMLManager.uploadITMS(account: UserCenter.shared.loginedUser.appleid, pwd: pwd, filePath: XMLManager.getITMSPath(self?.currentApp!.appId ?? "null"))
                DispatchQueue.main.async {
                    APHUD.hide()
                    self?.enterBtn.isEnabled = true
                    self?.closeSelfAndCallBack(result)
                }
            }
        }
        
        weak var weakSelf = self
        let pwd = UserCenter.shared.developerKey
        if pwd.isEmpty {
            let sb = NSStoryboard(name: "APPasswordVC", bundle: Bundle(for: self.classForCoder))
            let pwdVC = sb.instantiateController(withIdentifier: "APPasswordVC") as? APPasswordVC
            pwdVC?.callBackFunc = { newPwd in
                UserCenter.shared.developerKey = newPwd
                uploadIAPs(newPwd)
            }
            pwdVC?.cancelBtnFunc = {
                APHUD.hide()
                weakSelf?.enterBtn.isEnabled = true
            }
            presentAsSheet(pwdVC!)
        } else {
            uploadIAPs(pwd)
        }
    }
    
    func reductPicSizeAndMD5() {
        for i in 0..<waitUploadModel.iaps.count {
            let model = waitUploadModel.iaps[i]
            var imgPath = ssPaths[model.file_name] ?? ""
            // 是否有路径
            if imgPath.count == 0, model.file_name == default_screenshot_file_name,
               let jpgPath = Bundle.main.path(forResource: default_screenshot_file_name, ofType: nil) {
               // 如果是默认图片名，使用默认图片
                imgPath = jpgPath
                ssPaths[default_screenshot_file_name] = jpgPath
            }
            waitUploadModel.iaps[i].size = URL.init(fileURLWithPath: imgPath).fileSize()
            waitUploadModel.iaps[i].checksum = URL.init(fileURLWithPath: imgPath).fileMD5()!
        }
        waitUploadModel.filePaths = ssPaths
    }
    
  
    
    func closeSelfAndCallBack(_ result: (Int32, String?)) {
        if result.0 == 0 {
            NSAlert.show("上传成功！稍后可在苹果后台查看~")
        }else {
            let sb = NSStoryboard(name: "APDebugVC", bundle: Bundle(for: self.classForCoder))
            let newWC = sb.instantiateController(withIdentifier: "APDebugWC") as? NSWindowController
            let logVC = newWC?.contentViewController as? APDebugVC
            newWC?.window?.title = "上传错误日志"
            logVC?.debugLog = result.1 ?? ""
            newWC?.showWindow(self)
        }
    }
}

// MARK: - 网络请求
extension InputExcelListVC {
    
    func fetchAppInfo(_ replay: Int = 3) {
        guard let appid = currentApp?.appId else {
            APHUD.hide(message: "当前 App 的 appleid 为空！", delayTime: 1)
            return
        }
        
        APClient.appInfo(appid: appid).request(showLoading: true) { [weak self] result, response, error in
            if let err = error {
                if replay > 0 {
                    self?.fetchAppInfo(replay-1)
                } else {
                    NSAlert.show(err.localizedDescription)
                }
                return
            }
            let info = AppInfo(body: result)
            self?.appInfo = info
        }
    }
    
}


// MARK: - NSTableViewDelegate
extension InputExcelListVC: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return waitUploadModel.iaps.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableColumn?.identifier.enumValue() {
        case ColumnIdetifier.id.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.id.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = String(row+1)
            return cell
        case ColumnIdetifier.productID.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.productID.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = waitUploadModel.iaps[row].product_id
            return cell
        case ColumnIdetifier.productName.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.productName.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = waitUploadModel.iaps[row].reference_name
            return cell
        case ColumnIdetifier.price.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.price.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = checkPris[row]
            if levelChargeMoney(string(from: waitUploadModel.iaps[row].wholesale_price_tier)) != checkPris[row] {
                cell?.textField?.textColor = NSColor.red
                checkErrorHandle()
            }else {
                cell?.textField?.textColor = NSColor.labelColor
            }
            return cell
        case ColumnIdetifier.level.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.level.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = string(from: waitUploadModel.iaps[row].wholesale_price_tier)
            return cell
        case ColumnIdetifier.productPds.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.productPds.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = waitUploadModel.iaps[row].description
            return cell
        case ColumnIdetifier.state.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.state.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = waitUploadModel.iaps[row].type.CNValue()
            return cell
        case ColumnIdetifier.screenshot.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.screenshot.cellValue, owner: self) as? ImageViewCell
            let file_name = screenshots[row]
            var imgPath = ssPaths[file_name] ?? ""
            if imgPath.count == 0, file_name == default_screenshot_file_name {
                imgPath = Bundle.main.path(forResource: default_screenshot_file_name, ofType: nil) ?? ""
            }
            cell?.imgSel.image = NSImage(contentsOfFile: imgPath)
            return cell
        case ColumnIdetifier.language.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.language.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = waitUploadModel.iaps[row].lang
            return cell
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        30
    }
    
    // 金额和金额等级对比有误
    func checkErrorHandle() {
        enterBtn.isEnabled = false
    }
}
