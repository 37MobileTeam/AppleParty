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
    @IBOutlet weak var preserveCurrentPriceBtn: NSButton!
    
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
    
    private var screenshotPaths = [String: String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        self.tableView.selectionHighlightStyle = .none
        self.tableView.sizeToFit()
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
        ascAPI.addMessage("密钥信息：\(ascKey.issuerID), \(ascKey.privateKeyID), \(ascKey.privateKey)")
        
        Task {
            // 1、获取当前账号下 app，判断是否包含当前 提交商品的 app
            guard let apps = await ascAPI.apps() else {
                self.enterBtn.isEnabled = true
                APHUD.hide()
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
        ascAPI.addMessage("开始上传内购商品：\(product.productId)，\(product.name) ")
        // 检查是否已经存在此商品，如果存在就修改信息，如果不存在就创建
        let iaps = oldIAPs.filter({ $0.attributes?.productID == product.productId })
        if let iap = iaps.first {
            ascAPI.addMessage("内购已经存在：\(product.productId) ，开始更新信息中...")
            // 0. 审核备注如果原来有值，而新字段无值，则使用原值
            var product = product
            if let note = iap.attributes?.reviewNote, product.reviewNote.isEmpty {
                product.reviewNote = note
            }
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
            
            // 5. 销售国家或地区
            await updateIAPAvailableTerritories(iapId: iap.id, product: product, ascAPI: ascAPI)
            
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
            
            // 5. 销售国家或地区
            await updateIAPAvailableTerritories(iapId: iap.id, product: product, ascAPI: ascAPI)
        }
        
        ascAPI.addMessage("内购商品：\(product.productId)，\(product.name) ，上传完成！\n")
    }
    
    /// 创建内购商品价格档位
    func updateIAPPricePoint(iapId: String, product: IAPProduct, ascAPI: APASCAPI) async {
        guard let schedule = product.priceSchedules else {
            ascAPI.addMessage("无价格计划表：\(product.productId) ，请确认！❌ ")
            return
        }
        
        let baseTerritory = schedule.baseTerritory
        let baseCustomerPrice = schedule.baseCustomerPrice.normalizePrice()
        
        ascAPI.addMessage("开始更新价格计划表：\(product.productId)，\(baseTerritory)，\(baseCustomerPrice) \n")
        
        let points = await ascAPI.fetchPricePoints(iapId: iapId, territory: [baseTerritory])
        if let point = points.filter({ $0.attributes?.customerPrice!.normalizePrice() == baseCustomerPrice }).first {
            var manualPrices: [Any] = []
            var included: [Any] = []
            
            ascAPI.addMessage("开始构建基准国家和自定价格：")
            // base Territory
            manualPrices.append(["id": baseTerritory, "type": "inAppPurchasePrices"])
            included.append(ascAPI.fetchInAppPurchasePriceSchedule(scheduleId: baseTerritory, pricePointId: point.id, iapId: iapId))
            
            // customerPrice
            for pricePoint in schedule.manualPrices {
                let territory = pricePoint.territory
                let customerPrice = pricePoint.customerPrice.normalizePrice()
                let points = await ascAPI.fetchPricePoints(iapId: iapId, territory: [territory])
                if let point = points.filter({ $0.attributes?.customerPrice!.normalizePrice() == customerPrice }).first {
                    manualPrices.append(["id": territory, "type": "inAppPurchasePrices"])
                    included.append(ascAPI.fetchInAppPurchasePriceSchedule(scheduleId: territory, pricePointId: point.id, iapId: iapId))
                } else {
                    ascAPI.addMessage("自定价格的内购价格点：\(territory)，\(customerPrice) ，未找到此档位！❌ ")
                }
            }
            
            ascAPI.saveLogs(log: "内购的基准国家和自定价格：\(manualPrices)，\(included)")
            
            if (await ascAPI.updateInAppPurchasePricePoint(iapId: iapId, baseTerritoryId: baseTerritory, manualPrices: manualPrices, included: included)) != nil {
                // 价格档位配置成功
                ascAPI.addMessage("内购价格点：\(baseTerritory)，\(baseCustomerPrice) ，更新价格成功！✅ ")
            } else {
                // 价格档位配置失败
                ascAPI.addMessage("内购价格点：\(baseTerritory)，\(baseCustomerPrice) ，更新价格失败！❌ ")
            }
        } else {
            // 找不到价格档位
            ascAPI.addMessage("基准国家的内购价格点：\(baseTerritory)，\(baseCustomerPrice) ，未找到此档位！❌ ")
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
    
    /// 销售国家或地区
    func updateIAPAvailableTerritories(iapId: String, product: IAPProduct, ascAPI: APASCAPI) async {
        let inAll = product.territories.availableInAllTerritories
        let summary = territoryInfo(product: product)
        ascAPI.addMessage("开始更新内购商品的销售国家/地区：\(summary)")
        
        guard !inAll else {
            ascAPI.addMessage("选择所有国家/地区销售，将来新国家/地区自动提供，更新成功！✅ ")
            return
        }
        
        /// 选择销售的国家或地区
        var territories: [[String: String]] = []
        product.territories.territories?.forEach({ territory in
            territories.append([
                "type": "territories",
                "id": territory.id
            ])
        })
        
        let inNew = product.territories.availableInNewTerritories
        let customerTerritory = product.territories.territories?.map({ $0.id }).joined(separator: ",") ?? "无"
        if (await ascAPI.updateInAppPurchasesAvailabilityTerritories(iapId: iapId, availableTerritories: territories, availableInNewTerritories: inNew)) != nil {
            ascAPI.addMessage("内购商品的销售国家/地区：\(customerTerritory) ，更新成功！✅ ")
        } else {
            ascAPI.addMessage("内购商品的销售国家/地区：\(customerTerritory) ，更新失败！❌ ")
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
            // 0. 审核备注如果原来有值，而新字段无值，则使用原值
            var product = product
            if let note = sub.attributes?.reviewNote, product.reviewNote.isEmpty {
                product.reviewNote = note
            }
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
            
            // 5. 销售国家或地区
            await updateSubscriptionAvailableTerritories(iapId: iap.id, product: product, ascAPI: ascAPI)
            
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
            
            // 5. 销售国家或地区
            await updateSubscriptionAvailableTerritories(iapId: iap.id, product: product, ascAPI: ascAPI)
        }
        
        ascAPI.addMessage("订阅商品：\(product.productId)，\(product.name) ，上传完成！\n")
    }
    
    
    /// 更新订阅商品的价格档位
    func updateSubscriptionPricePoint(iapId: String, product: IAPProduct, ascAPI: APASCAPI) async {
        guard let schedule = product.priceSchedules else {
            ascAPI.addMessage("无价格计划表：\(product.productId) ，请确认！❌ ")
            return
        }
        
        let baseTerritory = schedule.baseTerritory
        let baseCustomerPrice = schedule.baseCustomerPrice.normalizePrice()
        
        ascAPI.addMessage("开始更新订阅商品价格点，基准国家：\(product.productId)，\(baseTerritory)，\(baseCustomerPrice) \n")
        
        let isPreservePrice = preserveCurrentPriceBtn.state.rawValue == 1
        ascAPI.addMessage("保留自动续期订阅者现有定价：\(isPreservePrice ? "是" : "否")")

        let points = await ascAPI.fetchSubscriptionPricePoints(iapId: iapId, territory: [baseTerritory])
        if let point = points.filter({ $0.attributes?.customerPrice!.normalizePrice() == baseCustomerPrice }).first {
            
            ascAPI.addMessage("开始更新自定价格：")
            // 自定价格的国家或地区, 基准国家也算是自定价格
            var customerPriceSchedules = schedule.manualPrices
            customerPriceSchedules.append(IAPPricePoint(territory: baseTerritory, customerPrice: baseCustomerPrice))
            let manualPricesTerritory: [String] = customerPriceSchedules.map({ $0.territory })
            // 设置自定价格
            for pricePoint in customerPriceSchedules {
                let territory = pricePoint.territory
                let customerPrice = pricePoint.customerPrice.normalizePrice()
                let points = await ascAPI.fetchSubscriptionPricePoints(iapId: iapId, territory: [territory])
                if let point = points.filter({ $0.attributes?.customerPrice!.normalizePrice() == customerPrice }).first {
                    if (await ascAPI.updateSubscriptionPricePoint(iapId: iapId, pricePointId: point.id, preserveCurrentPrice: isPreservePrice)) != nil {
                        ascAPI.addMessage("自定价格的订阅商品的价格点：\(territory)，\(customerPrice) ，更新价格成功！✅ ")
                    } else {
                        ascAPI.addMessage("自定价格的订阅商品的价格点：\(territory)，\(customerPrice) ，更新价格失败！❌ ")
                    }
                } else {
                    ascAPI.addMessage("自定价格的订阅商品价格点：\(territory)，\(customerPrice) ，未找到此档位！❌ ")
                }
            }
            
            ascAPI.addMessage("开始更新全球均衡价格：")
            // 剩余的所有的国家地区的订阅价格点，然后一个一个设置。API不支持全部国家一次配置
            let allPoints = await ascAPI.fetchSubscriptionPricePointsEqualizations(pointId: point.id, territory: nil)
            for apoint in allPoints {
                let territory = apoint.relationships?.territory?.data?.id ?? ""
                // 自定价格的国家跳过
                if manualPricesTerritory.contains(territory) {
                    continue
                }
                let customerPrice = apoint.attributes?.customerPrice ?? ""
                if (await ascAPI.updateSubscriptionPricePoint(iapId: iapId, pricePointId: apoint.id, preserveCurrentPrice: isPreservePrice)) != nil {
                    // 价格档位配置成功
                    ascAPI.addMessage("全球均衡价格的订阅商品的价格点：\(territory)，\(customerPrice) ，更新价格成功！✅ ")
                } else {
                    // 价格档位配置失败
                    ascAPI.addMessage("全球均衡价格的订阅商品的价格点：\(territory)，\(customerPrice) ，更新价格失败！❌ ")
                }
            }
        } else {
            // 找不到价格档位
            ascAPI.addMessage("基准国家的订阅商品价格点：\(baseTerritory)，\(baseCustomerPrice) ，未找到此档位！❌ ")
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
    
    /// 销售国家或地区
    func updateSubscriptionAvailableTerritories(iapId: String, product: IAPProduct, ascAPI: APASCAPI) async {
        let inAll = product.territories.availableInAllTerritories
        let summary = territoryInfo(product: product)
        ascAPI.addMessage("开始更新订阅商品的销售国家/地区：\(summary)")
        
        guard !inAll else {
            ascAPI.addMessage("选择所有国家/地区销售，将来新国家/地区自动提供，更新成功！✅ ")
            return
        }
        
        /// 选择销售的国家或地区
        var territories: [[String: String]] = []
        product.territories.territories?.forEach({ territory in
            territories.append([
                "type": "territories",
                "id": territory.id
            ])
        })
        
        let inNew = product.territories.availableInNewTerritories
        let customerTerritory = product.territories.territories?.map({ $0.id }).joined(separator: ",") ?? "无"
        if (await ascAPI.updateSubscriptionAvailabilityTerritories(iapId: iapId, availableTerritories: territories, availableInNewTerritories: inNew)) != nil {
            ascAPI.addMessage("订阅商品的销售国家/地区：\(customerTerritory) ，更新成功！✅ ")
        } else {
            ascAPI.addMessage("订阅商品的销售国家/地区：\(customerTerritory) ，更新失败！❌ ")
        }
    }
}

// MARK: - Privacy Method
extension APUploadIAPListVC {
    
    func territoryInfo(product: IAPProduct) -> String {
        let inAll = product.territories.availableInAllTerritories
        let inNew = product.territories.availableInNewTerritories
        let customerTerritory = product.territories.territories?.map({ $0.id }).joined(separator: ",") ?? ""
        let off = !inAll && !inNew && (product.territories.territories?.isEmpty ?? true)
        let territory = off ? "下架" : (customerTerritory.isEmpty ? (inAll ? "全部" : "当前下架") : customerTerritory)
        let stringValue = "在所有国家/地区销售：'\(inAll ? "是" : "否")'\n将来新国家/地区自动提供：'\(inNew ? "是" : "否")'\n指定国家/地区销售：\(territory)"
        return stringValue
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
            cell?.textField?.stringValue = territoryInfo(product: iap)
            return cell
        case ColumnIdetifier.level.cellValue:
            let cell = tableView.makeView(withIdentifier: ColumnIdetifier.level.cellValue, owner: self) as? NSTableCellView
            let territory = iap.priceSchedules?.baseTerritory ?? "-"
            let price = iap.priceSchedules?.baseCustomerPrice ?? "-"
            let customerPrice = iap.priceSchedules?.manualPrices.map({ pp in
                "{'国家:'\(pp.territory)', '自定价格':'\(pp.customerPrice)'}\n"
            }).joined() ?? "-"
            cell?.textField?.stringValue = "基准国家：'\(territory)'\n基准价格：'\(price)'\n\(customerPrice)"
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
            cell?.textField?.stringValue = iap.localizations.map({ lz in
                "{'locale:'\(lz.locale)', 'title':'\(lz.name)', 'desc':'\(lz.description)'}\n"
            }).joined()
            return cell
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let prices = iaps[row].priceSchedules?.manualPrices.count ?? 0
        let count = max(prices + 2, 3)
        return count > 10 ? CGFloat(20 * count) : CGFloat(25 * count)
    }
}
