//
//  InputTableListVC.swift
//  AppleParty
//
//  Created by 易承 on 2020/12/15.
//

import Cocoa

class APUploadIAPListVC: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var enterBtn: NSButton!
    @IBOutlet weak var priceSelectPopupBtn: NSPopUpButton!
    
    public var currentApp: App? {
        didSet {
            setupUI()
        }
    }
    public var iaps =  [IAPProduct]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private var checkPrice = [String: String]()
    private var checkPris = [String]()
    private var screenshotPaths = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        self.tableView.selectionHighlightStyle = .none
        self.tableView.sizeToFit()
        
        clickedPriceSelectPopupBtn(priceSelectPopupBtn)
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
            let screenshot = self.iaps.filter({ $0.reviewScreenshot.count > 0 }).map({ $0.reviewScreenshot })
            // 去重后的图片名
            let uniquedshot = screenshot.enumerated().filter { (index, value) -> Bool in
                return screenshot.firstIndex(of: value) == index
            }.map { $0.element }
            upVC?.picnames = uniquedshot
            upVC?.callBackFunc = { paths in
                self.screenshotPaths = paths
                self.tableView.reloadData()
            }
            self.presentAsSheet(upVC!)
        }
    }
    
    @IBAction func clickedPriceSelectPopupBtn(_ sender: NSPopUpButton) {
        updateCheckPrice(index: sender.selectedTag())
    }
    
    func updateCheckPrice(index: Int) {
        var countryCode = "CN"
        switch index {
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
        
        self.checkPrice = PriceTierParser.priceTiers(countryCode)
        self.tableView.reloadData()
    }
    
    @IBAction func clickedUploadShotBtn(_ sender: Any) {
        showUploadView()
    }
    
    @IBAction func clickedSPasswordBtn(_ sender: Any) {
        let vc = APASCKeysSettingVC()
        presentAsSheet(vc)
    }
    
    @IBAction func createIAP(_ sender: Any) {
        let list = self.iaps
        guard list.count > 0 else {
            APHUD.hide(message: "当前 App 无上传的内购商品！", delayTime: 1)
            return
        }
        
        
        guard let appid = currentApp?.appId else {
            APHUD.hide(message: "当前 App 的 appleid 为空！", delayTime: 1)
            return
        }
        
        enterBtn.isEnabled = false
        APHUD.show(message: "上传中", view: self.view)
        let uploadIAPs: ((AppStoreConnectKey) -> Void) = { [weak self] ascKey in
            // 上传数据
            self?.updateInAppPurchse(iaps: list, appId: appid, ascKey: ascKey)
        }
        
        guard let ascKey = InfoCenter.shared.currentASCKey else {
            let vc = APASCKeysSettingVC()
            vc.updateCompletion = { password in
                if let ascKey = password  {
                    uploadIAPs(ascKey)
                }
            }
            presentAsSheet(vc)
            return
        }
        
        uploadIAPs(ascKey)
    }

}

// MARK: - 网络请求
extension APUploadIAPListVC {
    
    func updateInAppPurchse(iaps: [IAPProduct], appId: String, ascKey: AppStoreConnectKey) {
        let ascAPI = APASCAPI.init(issuerID: ascKey.issuerID,
                               privateKeyID: ascKey.privateKeyID,
                                 privateKey: ascKey.privateKey)
        Task {
            // 1、获取当前账号下 app，判断是否包含当前 提交商品的 app
            guard let apps = await ascAPI.apps() else {
                APHUD.hide(message: "当前请求异常，请检查密钥是否正确~", delayTime: 2)
                return
            }
            let app = apps.filter { $0.id == appId }
            guard app.count > 0 else {
                self.enterBtn.isEnabled = true
                APHUD.hide()
                APHUD.hide(message: "当前的密钥没有查到App: \(appId)，请检查~", delayTime: 2)
                return
            }
            
            // 2. 同步显示进度日志
            let sb = NSStoryboard(name: "APDebugVC", bundle: Bundle(for: self.classForCoder))
            let newWC = sb.instantiateController(withIdentifier: "APDebugWC") as? NSWindowController
            newWC?.window?.title = "内购批量上传日志"
            let logVC = newWC?.contentViewController as? APDebugVC
            logVC?.debugLog = "开始上传"
            newWC?.showWindow(self)
            ascAPI.updateMsg = { messages in
                logVC?.debugLog = messages.joined(separator: "\n")
            }
            
            ascAPI.addMessage("开始处理内购商品，获取现有商品中...")
            // 3、获取所有的内购商品，如果存在的商品就直接修改，如果不存在就创建
            let oldIAPs = await ascAPI.fetchInAppPurchasesList(appId: appId)
            
            // 4、遍历所有要上传的商品
            for product in iaps {
                // 订阅类型与非订单类型不一样的处理逻辑
                if product.inAppPurchaseType == .AUTO_RENEWABLE {
                    await createRenewSubscription(appId: appId, product: product, ascAPI: ascAPI)
                } else {
                    await createInAppPurchase(appId: appId, product: product, oldIAPs: oldIAPs, ascAPI: ascAPI)
                }
            }
            
            self.enterBtn.isEnabled = true
            APHUD.hide()
            ascAPI.addMessage("完成全部内购商品，可稍后在苹果后台查看！✅✅✅")
        }
    }
    
    // MARK: - 上传内购类型商品
    
    /// 创建内购商品
    func createInAppPurchase(appId: String, product: IAPProduct, oldIAPs: [ASCInAppPurchaseV2], ascAPI: APASCAPI) async {
        ascAPI.addMessage("开始上传内购商品：\(product.productId)，\(product.priceTier)，\(product.name) ")
        // 检查是否已经存在此商品，如果存在就修改信息，如果不存在就创建
        let iaps = oldIAPs.filter({ $0.attributes?.productID == product.productId })
        if let iap = iaps.first {
            ascAPI.addMessage("内购已经存在：\(product.productId) ，开始更新信息中...")
            // 1.修改原商品信息
            guard let iap = await ascAPI.updateInAppPurchases(iapId: iap.id, product: product) else {
                // 修改失败
                ascAPI.addMessage("内购已经存在：\(product.productId) ，更新信息失败！❌ ")
                return
            }
            // 2. 商品价格档位
            await updateIAPPricePoint(iapId: iap.id, product: product, ascAPI: ascAPI)
            
            // 3. 商品本地化语言
            ascAPI.addMessage("开始更新内购本地化版本：\(product.productId)")
            let localizations = await ascAPI.fetchInAppPurchasesLocalizations(iapId: iap.id)
            for localization in product.localizations {
                // 如果已经存在本地化语言，则更新
                if let locale = localizations.filter({ $0.attributes?.locale == localization.locale }).first {
                    // 更新
                    ascAPI.addMessage("内购已存在本地化版本：\(localization.locale)，开始更新信息中...")
                    if (await ascAPI.updateInAppPurchasesLocalization(iapLocaleId: locale.id, localization: localization)) != nil {
                        // 本地化语言更新成功
                        ascAPI.addMessage("内购本地化版本：\(localization.locale) ，更新语言成功！✅ ")
                    } else {
                        // 本地化语言更新失败
                        ascAPI.addMessage("内购本地化版本：\(localization.locale) ，更新语言失败！❌ ")
                    }
                } else {
                    // 创建
                    await createIAPLocalization(iapId: iap.id, localization: localization, product: product, ascAPI: ascAPI)
                }
            }
            
            // 4. 商品截图
            await createIAPScreenshot(iapId: iap.id, product: product, ascAPI: ascAPI)
            
        } else {
            // 1. 创建新的商品
            guard let iap = await ascAPI.createInAppPurchases(appId: appId, product: product) else {
                // 创建失败
                ascAPI.addMessage("内购商品：\(product.productId) ，创建失败！❌ ")
                return
            }
            // 2. 商品价格档位
            await updateIAPPricePoint(iapId: iap.id, product: product, ascAPI: ascAPI)
            
            // 3. 商品本地化语言
            for localization in product.localizations {
                await createIAPLocalization(iapId: iap.id, localization: localization, product: product, ascAPI: ascAPI)
            }
            
            // 4. 商品截图
            await createIAPScreenshot(iapId: iap.id, product: product, ascAPI: ascAPI)
        }
        
        ascAPI.addMessage("内购商品：\(product.productId)，\(product.priceTier)，\(product.name) ，上传完成！")
    }
    
    /// 创建内购商品价格档位
    func updateIAPPricePoint(iapId: String, product: IAPProduct, ascAPI: APASCAPI) async {
        ascAPI.addMessage("开始更新价格档位：\(product.productId)，\(product.priceTier)")
        let priceTier = product.priceTier
        let points = await ascAPI.fetchPricePoints(iapId: iapId, territory: ["USA"])
        if let point = points.filter({ $0.attributes?.priceTier == priceTier }).first {
            if (await ascAPI.updateInAppPurchasePricePoint(iapId: iapId, priceTierId: priceTier, pricePointId: point.id)) != nil {
                // 价格档位配置成功
                ascAPI.addMessage("内购价格档位：\(priceTier) ，更新价格成功！✅ ")
            } else {
                // 价格档位配置失败
                ascAPI.addMessage("内购价格档位：\(priceTier) ，更新价格失败！❌ ")
            }
        } else {
            // 找不到价格档位
            ascAPI.addMessage("内购价格档位：\(priceTier) ，无找到此档位！❌ ")
        }
    }
    
    
    /// 创建内购商品本地化信息
    func createIAPLocalization(iapId: String, localization: IAPLocalization, product: IAPProduct, ascAPI: APASCAPI) async {
        ascAPI.addMessage("开始更新本地化版本：\(product.productId)，\(localization.locale)")
        if (await ascAPI.createInAppPurchasesLocalization(iapId: iapId, localization: localization)) != nil {
            // 本地化语言配置成功
            ascAPI.addMessage("内购本地化版本：\(localization.locale) ，更新语言成功！✅ ")
        } else {
            // 本地化语言配置失败
            ascAPI.addMessage("内购本地化版本：\(localization.locale) ，更新语言失败！❌ ")
        }
    }
    
    /// 更新内购商品的送审截图
    func createIAPScreenshot(iapId: String, product: IAPProduct, ascAPI: APASCAPI) async {
        ascAPI.addMessage("开始更新内购商品的送审截图：\(product.productId)，\(product.reviewScreenshot)")
        let imgName = product.reviewScreenshot
        guard let imgPath = screenshotPaths[imgName] else {
            ascAPI.addMessage("内购商品：\(product.productId) 无送审截图或未上传截图~")
            return
        }
        
        let imaUrl = URL.init(fileURLWithPath: imgPath)
        guard let fileMD5 = URL.init(fileURLWithPath: imgPath).fileMD5() else {
            ascAPI.addMessage("内购商品截图文件错误：\(imgPath) ，无法生成 md5 值~")
            return
        }

        let oldShot = await ascAPI.fetchInAppPurchasesScreenshot(iapId: iapId)
        // 存在需要删除，避免文件名不一样或者过期文件
        if let ost = oldShot {
            ascAPI.addMessage("删除旧的送审截图：\(ost.attributes?.fileName ?? "")")
            let status = await ascAPI.deleteInAppPurchasesScreenshot(iapShotId: ost.id)
            if status != 204 {
                ascAPI.addMessage("内购商品截图创建失败：\(imgName) ，无法删除旧截图~")
            }
        }
        
        ascAPI.addMessage("创建新的送审截图：\(product.reviewScreenshot)")
        // 创建截图
        let imaSize = imaUrl.fileSizeInt()
        guard let shot = await ascAPI.createInAppPurchasesScreenshot(iapId: iapId, fileName: imgName, fileSize: imaSize) else {
            // 创建失败
            ascAPI.addMessage("内购商品：\(product.productId) ，创建送审截图失败！❌ ")
            return
        }
        
        // 根据苹果接口返回的上传接口上传
        guard let method = shot.attributes?.uploadOperations?.first?.method,
              let url = shot.attributes?.uploadOperations?.first?.url,
              let requestHeaders = shot.attributes?.uploadOperations?.first?.requestHeaders,
              let baseURL = URL(string: url) else {
                  ascAPI.addMessage("内购商品：\(product.productId) ，创建送审截图失败！苹果参数异常~ ❌ ")
                  return
              }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = method
        for header in requestHeaders {
            request.headers[header.name ?? ""] = header.value ?? ""
        }
        
        ascAPI.addMessage("上传新的送审截图：\(product.reviewScreenshot)")
        // 上传图片
        guard let response = try? await URLSession.shared.upload(for: request, fromFile: imaUrl) else {
            ascAPI.addMessage("内购商品：\(product.productId) ，创建送审截图失败！上传图片异常~ ❌ ")
            return
        }
        guard let responseCode = (response.1 as? HTTPURLResponse)?.statusCode, responseCode == 200 else {
            ascAPI.addMessage("内购商品：\(product.productId) ，创建送审截图失败！上传图片异常 \(response.1.description)~ ❌ ")
            return
        }
        
        ascAPI.addMessage("提交新的送审截图：\(product.reviewScreenshot)")
        // 确认图片
        if ((await ascAPI.updateInAppPurchasesScreenshot(iapShotId: shot.id, fileMD5: fileMD5)) != nil) {
            ascAPI.addMessage("内购商品：\(product.productId) ，送审截图上传成功！✅ ")
        } else {
            ascAPI.addMessage("内购商品：\(product.productId) ，送审截图可能上传失败！ ")
        }
    }
    
    // MARK: - 上传订阅商品
    
    /// 订阅商品创建或更新
    func createRenewSubscription(appId: String, product: IAPProduct, ascAPI: APASCAPI) async {
        // 1、是否有订阅组，没有时要先创建
        var subGroups = await ascAPI.fetchSubscriptionGroups(appId: appId)
        if subGroups.isEmpty {
            // 创建订阅组
            if let group = await ascAPI.createSubscriptionGroups(appId: appId) {
                subGroups.append(group)
            }
        }
        
        // 2、有订阅组，获取所有订阅组的所有订阅商品
        var subscriptions = [ASCSubscription]()
        for subGroup in subGroups {
            let subs = await ascAPI.fetchSubscriptionGroupSubscriptions(iapGroupId: subGroup.id)
            subscriptions.append(contentsOf: subs)
        }
        
        // 3、查看是否存在订阅商品，不存在就创建，存在就更新
        let subs = subscriptions.filter({ $0.attributes?.productID == product.productId })
        if let sub = subs.first {
            ascAPI.addMessage("订阅商品已经存在：\(product.productId) ，开始更新信息中...")
            // 1.修改原商品信息
            guard let iap = await ascAPI.updateSubscription(iapId: sub.id, product: product) else {
                // 修改失败
                ascAPI.addMessage("订阅商品已经存在：\(product.productId) ，更新信息失败！❌ ")
                return
            }
            
            // 2. 商品本地化语言
            ascAPI.addMessage("开始更新订阅商品本地化版本：\(product.productId)")
            let localizations = await ascAPI.fetchSubscriptionLocalizations(iapId: iap.id)
            for localization in product.localizations {
                // 如果已经存在本地化语言，则更新
                if let locale = localizations.filter({ $0.attributes?.locale == localization.locale }).first {
                    // 更新
                    ascAPI.addMessage("订阅商品已存在本地化版本：\(localization.locale)，开始更新信息中...")
                    if (await ascAPI.updateSubscriptionLocalization(iapLocaleId: locale.id, localization: localization)) != nil {
                        // 本地化语言更新成功
                        ascAPI.addMessage("订阅商品本地化版本：\(localization.locale) ，更新语言成功！✅ ")
                    } else {
                        // 本地化语言更新失败
                        ascAPI.addMessage("订阅商品本地化版本：\(localization.locale) ，更新语言失败！❌ ")
                    }
                } else {
                    // 创建
                    await createSubscriptionLocalization(iapId: iap.id, localization: localization, product: product, ascAPI: ascAPI)
                }
            }
            
            // 3. 商品价格档位
            await updateSubscriptionPricePoint(iapId: iap.id, product: product, ascAPI: ascAPI)
            
            // 4. 商品截图
            await createSubscriptionScreenshot(iapId: iap.id, product: product, ascAPI: ascAPI)
            
        } else {
            // 1. 创建新的商品
            guard let iapGroupId = subGroups.first?.id, let iap = await ascAPI.createSubscription(iapGroupId: iapGroupId, product: product) else {
                // 创建失败
                ascAPI.addMessage("订阅商品：\(product.productId) ，创建失败！❌ ")
                return
            }
            
            // 2. 商品本地化语言
            for localization in product.localizations {
                await createSubscriptionLocalization(iapId: iap.id, localization: localization, product: product, ascAPI: ascAPI)
            }
            
            // 3. 商品价格档位
            await updateSubscriptionPricePoint(iapId: iap.id, product: product, ascAPI: ascAPI)
            
            // 4. 商品截图
            await createSubscriptionScreenshot(iapId: iap.id, product: product, ascAPI: ascAPI)
        }
        
        ascAPI.addMessage("订阅商品：\(product.productId)，\(product.priceTier)，\(product.name) ，上传完成！")
    }
    
    
    /// 更新订阅商品的价格档位
    func updateSubscriptionPricePoint(iapId: String, product: IAPProduct, ascAPI: APASCAPI) async {
        ascAPI.addMessage("开始更新订阅商品价格档位：\(product.productId)，\(product.priceTier)")
        let priceTier = product.priceTier
        let checkPrice = PriceTierParser.priceTiers("US")
        guard let price = checkPrice[priceTier] else {
            ascAPI.addMessage("订阅商品价格档位：\(priceTier) ，无匹配的档位价格！请在苹果后台选择价格~❌ ")
            return
        }
        let points = await ascAPI.fetchSubscriptionPricePoints(iapId: iapId, territory: ["USA"])
        if let point = points.filter({ $0.attributes?.customerPrice == price }).first {
            // 获取所有的国家地区的订阅价格点，然后一个一个设置。API不支持全部国家一次配置
            let allPoints = await ascAPI.fetchSubscriptionPricePointsEqualizations(pointId: point.id, territory: nil)
            for apoint in allPoints {
                let territory = apoint.relationships?.territory?.data?.id ?? ""
                if (await ascAPI.updateSubscriptionPricePoint(iapId: iapId, pricePointId: apoint.id)) != nil {
                    // 价格档位配置成功
                    ascAPI.addMessage("\(territory) 订阅商品价格档位：\(priceTier) ，更新价格成功！✅ ")
                } else {
                    // 价格档位配置失败
                    ascAPI.addMessage("\(territory) 订阅商品价格档位：\(priceTier) ，更新价格失败！❌ ")
                }
            }
        } else {
            // 找不到价格档位
            ascAPI.addMessage("订阅商品价格档位：\(priceTier) ，无找到此档位！❌ ")
        }
    }
    
    
    /// 更新订阅商品的本地化信息
    func createSubscriptionLocalization(iapId: String, localization: IAPLocalization, product: IAPProduct, ascAPI: APASCAPI) async {
        ascAPI.addMessage("开始更新订阅商品本地化版本：\(product.productId)，\(localization.locale)")
        if (await ascAPI.createSubscriptionLocalization(iapId: iapId, localization: localization)) != nil {
            // 本地化语言配置成功
            ascAPI.addMessage("订阅商品本地化版本：\(localization.locale) ，更新语言成功！✅ ")
        } else {
            // 本地化语言配置失败
            ascAPI.addMessage("订阅商品本地化版本：\(localization.locale) ，更新语言失败！❌ ")
        }
    }
    
    /// 更新订阅商品的送审截图
    func createSubscriptionScreenshot(iapId: String, product: IAPProduct, ascAPI: APASCAPI) async {
        ascAPI.addMessage("开始更新订阅商品的送审截图：\(product.productId)，\(product.reviewScreenshot)")
        let imgName = product.reviewScreenshot
        guard let imgPath = screenshotPaths[imgName] else {
            ascAPI.addMessage("订阅商品：\(product.productId) 无送审截图或未上传截图~")
            return
        }
        
        let imaUrl = URL.init(fileURLWithPath: imgPath)
        guard let fileMD5 = URL.init(fileURLWithPath: imgPath).fileMD5() else {
            ascAPI.addMessage("订阅商品截图文件错误：\(imgPath) ，无法生成 md5 值~")
            return
        }

        let oldShot = await ascAPI.fetchSubscriptionScreenshot(iapId: iapId)
        // 存在需要删除，避免文件名不一样或者过期文件
        if let ost = oldShot {
            ascAPI.addMessage("删除旧的送审截图：\(ost.attributes?.fileName ?? "")")
            let status = await ascAPI.deleteSubscriptionScreenshot(iapShotId: ost.id)
            if status != 204 {
                ascAPI.addMessage("订阅商品截图创建失败：\(imgName) ，无法删除旧截图~")
            }
        }
        
        ascAPI.addMessage("创建新的送审截图：\(product.reviewScreenshot)")
        // 创建截图
        let imaSize = imaUrl.fileSizeInt()
        guard let shot = await ascAPI.createSubscriptionScreenshot(iapId: iapId, fileName: imgName, fileSize: imaSize) else {
            // 创建失败
            ascAPI.addMessage("订阅商品：\(product.productId) ，创建送审截图失败！❌ ")
            return
        }
        
        // 根据苹果接口返回的上传接口上传
        guard let method = shot.attributes?.uploadOperations?.first?.method,
              let url = shot.attributes?.uploadOperations?.first?.url,
              let requestHeaders = shot.attributes?.uploadOperations?.first?.requestHeaders,
              let baseURL = URL(string: url) else {
                  ascAPI.addMessage("订阅商品：\(product.productId) ，创建送审截图失败！苹果参数异常~ ❌ ")
                  return
              }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = method
        for header in requestHeaders {
            request.headers[header.name ?? ""] = header.value ?? ""
        }
        
        ascAPI.addMessage("上传新的送审截图：\(product.reviewScreenshot)")
        // 上传图片
        guard let response = try? await URLSession.shared.upload(for: request, fromFile: imaUrl) else {
            ascAPI.addMessage("订阅商品：\(product.productId) ，创建送审截图失败！上传图片异常~ ❌ ")
            return
        }
        guard let responseCode = (response.1 as? HTTPURLResponse)?.statusCode, responseCode == 200 else {
            ascAPI.addMessage("订阅商品：\(product.productId) ，创建送审截图失败！上传图片异常 \(response.1.description)~ ❌ ")
            return
        }
        
        ascAPI.addMessage("提交新的送审截图：\(product.reviewScreenshot)")
        // 确认图片
        if ((await ascAPI.updateSubscriptionScreenshot(iapShotId: shot.id, fileMD5: fileMD5)) != nil) {
            ascAPI.addMessage("订阅商品：\(product.productId) ，送审截图上传成功！✅ ")
        } else {
            ascAPI.addMessage("订阅商品：\(product.productId) ，送审截图可能上传失败！ ")
        }
    }
}


// MARK: - NSTableViewDelegate
extension APUploadIAPListVC: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return iaps.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let iap = iaps[row]
        switch tableColumn?.identifier.enumValue() {
        case ColumnIdetifier.id.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.id.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = String(row+1)
            return cell
        case ColumnIdetifier.productID.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.productID.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = iap.productId
            return cell
        case ColumnIdetifier.productName.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.productName.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = iap.name
            return cell
        case ColumnIdetifier.price.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.price.cellValue, owner: self) as? NSTableCellView
            let price = iap.price
            let retailPrice = checkPrice[iap.priceTier]
            if let retailPrice = retailPrice, retailPrice != iap.price {
                cell?.textField?.textColor = NSColor.red
                cell?.textField?.stringValue = "\(price)->\(String(describing: retailPrice))"
            } else {
                cell?.textField?.textColor = NSColor.labelColor
                cell?.textField?.stringValue = iap.price
            }
            return cell
        case ColumnIdetifier.level.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.level.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = iap.priceTier
            return cell
        case ColumnIdetifier.productPds.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.productPds.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = iap.reviewNote
            return cell
        case ColumnIdetifier.state.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.state.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.stringValue = iap.inAppPurchaseType.CNValue()
            return cell
        case ColumnIdetifier.screenshot.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.screenshot.cellValue, owner: self) as? ImageViewCell
            let file_name = iap.reviewScreenshot
            let imgPath = screenshotPaths[file_name] ?? ""
            cell?.imgSel.image = NSImage(contentsOfFile: imgPath)
            return cell
        case ColumnIdetifier.language.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.language.cellValue, owner: self) as? NSTableCellView
            cell?.textField?.usesSingleLineMode = false
            cell?.textField?.stringValue = iap.localizations.map({ lz in
                "{'locale:'\(lz.locale)', 'title':'\(lz.name)', 'desc':'\(lz.description)'}\n"
            }).joined()
            return cell
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let count = iaps[row].localizations.count
        return count == 0 ?  30 : CGFloat(20 * (count + 1))
    }
}
