//
//  SettingVC.swift
//  AppleParty
//
//  Created by HTC on 2021/9/25.
//  Copyright © 2021 37 Mobile Games. All rights reserved.
//

import Cocoa

class APSettingVC: NSViewController {
    
    // 完成回调通知
    var finishBlock: (([String]) -> Void)?
    // 处理结果
    var errorsList = [String]()
    var results = [String:[String:[Any]]]()
    var dataPath: String = "default"
    var commonPath: URL {
        var documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        documentsURL.appendPathComponent("AppleParty")
        return documentsURL
    }
    var logFilePath: URL {
        get {
            var documentsURL = commonPath
            documentsURL.appendPathComponent("Notification")
            documentsURL.appendPathComponent("\(dataPath)_log.txt")
            createFileDirectory(url: documentsURL)
            return documentsURL
        }
    }
    
    // 定时同步时间：小时
    var syncHourString: String {
        get { string(from: UserDefaults.standard.object(forKey: "SettingVC_syncHourString")) }
        set { UserDefaults.standard.setValue(newValue, forKey: "SettingVC_syncHourString") }
    }
    // 定时同步时间：分钟
    var syncMinuteString: String {
        get { string(from: UserDefaults.standard.object(forKey: "SettingVC_syncMinuteString")) }
        set { UserDefaults.standard.setValue(newValue, forKey: "SettingVC_syncMinuteString") }
    }
    // 邮件通知
    var isSendEmail: Bool {
        get { bool(from: UserDefaults.standard.object(forKey: "SettingVC_isSendEmail")) }
        set { UserDefaults.standard.setValue(newValue, forKey: "SettingVC_isSendEmail") }
    }
    // 邮件地址
    var syncEmailsString: String {
        get { string(from: UserDefaults.standard.object(forKey: "SettingVC_syncEmailsString")) }
        set { UserDefaults.standard.setValue(newValue, forKey: "SettingVC_syncEmailsString") }
    }
    // 消息
    var messagesDB: [String: [String:Any]] {
        get {
            if let data = UserDefaults.standard.object(forKey: "SettingVC_messagesDB") as? Data, let db = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: [String:Any]] {
                return db
            }
            return [:]
        }
        set {
            UserDefaults.standard.setValue(NSKeyedArchiver.archivedData(withRootObject: newValue), forKey: "SettingVC_messagesDB")
        }
    }
    
    var isLoginViewShow: Bool {
        get { return false  }
        set {
            sPasswordBtn.isHidden = newValue
            AccontTitleLbl.isHidden = newValue
            timingSyncBtn.isHidden = newValue
            syncHoursTF.isHidden = newValue
            syncMinutesTF.isHidden = newValue
            emailSyncBtn.isHidden = newValue
            notiEmailsTF.isHidden = newValue
            manualSyncBtn.isHidden = newValue
            clearCacheBtn.isHidden = !newValue
            AccountLine.isHidden = newValue
            clearCachePwBtnLeadingConstraint.priority = newValue == true ? .defaultLow : .defaultHigh
        }
    }
    
    @IBOutlet weak var trusDeviceBtn: NSButton!
    @IBOutlet weak var sPasswordBtn: NSButton!
    @IBOutlet weak var AccontTitleLbl: NSTextField!
    @IBOutlet weak var timingSyncBtn: NSButton!
    @IBOutlet weak var syncHoursTF: NSTextField!
    @IBOutlet weak var syncMinutesTF: NSTextField!
    @IBOutlet weak var emailSyncBtn: NSButton!
    @IBOutlet weak var notiEmailsTF: NSTextField!
    @IBOutlet weak var manualSyncBtn: NSButton!
    @IBOutlet weak var clearCacheBtn: NSButton!
    @IBOutlet var AccountLine: NSView!
    
    @IBOutlet weak var clearCachePwBtnLeadingConstraint: NSLayoutConstraint!
    
    
    @IBAction func clickedSAccountBtn(_ sender: NSButton) {
        InfoCenter.shared.trusDevice = sender.state == .on ? true : false
    }
    
    @IBAction func clickedSPasswordBtn(_ sender: Any) {
        let sb = NSStoryboard(name: "APPasswordVC", bundle: Bundle(for: self.classForCoder))
        let pwdVC = sb.instantiateController(withIdentifier: "APPasswordVC") as? APPasswordVC
        pwdVC?.callBackFunc = { pwd in
            UserCenter.shared.developerKey = pwd
        }
        presentAsSheet(pwdVC!)
    }
    
    @IBAction func clickedClearCacheBtn(_ sender: NSButton) {
        // 清掉缓存
        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
        InfoCenter.shared.cookies = []
        APHUD.hide(message: "清掉缓存成功", view: self.view)
    }
    
    @IBAction func clickedSettingNotiBtn(_ sender: NSButton) {
        // 取消定时任务
        if sender.state == .off {
            TimerUtils.shard.invalidateNotificationTimer()
            return
        }
        // 检查定时时间的格式
        let hours = syncHoursTF.stringValue
        let minutes = syncMinutesTF.stringValue
        guard hours.isNotEmpty, minutes.isNotEmpty else {
            APHUD.hide(message: "间隔时间不能为空！", view: self.view)
            sender.state = .off
            return
        }
        guard let hour = Int(hours), let minute = Int(minutes) else {
            APHUD.hide(message: "间隔时间只能是数字！", view: self.view)
            sender.state = .off
            return
        }
        
        let time = hour * 60 * 60 + minute * 60
        guard time > 0 else {
            APHUD.hide(message: "间隔时间必然大于0！", view: self.view)
            sender.state = .off
            return
        }
        
        // 保存时间
        syncHourString = hours
        syncMinuteString = minutes
        // 执行间隔定时任务
        TimerUtils.shard.startNotificationTimer(interval: TimeInterval(time))
    }
    
    @IBAction func clickedEmailSyncBtn(_ sender: NSButton) {
        if sender.state == .off {
            isSendEmail = false
            return
        }
        // 读取定时时间
        let emailsString = notiEmailsTF.stringValue
        guard emailsString.isNotEmpty else {
            APHUD.hide(message: "同步通知的邮箱地址不能为空！", view: self.view)
            sender.state = .off
            return
        }
        // 邮件格式是否正确
        let allEmails = emailsString.components(separatedBy: [";", "；", ","]).filter({!$0.isEmpty})
        let emails = allEmails.filter({ isEmailValid($0) })
        guard allEmails.count == emails.count, emails.count > 0 else {
            APHUD.hide(message: "邮箱地址格式有误，请检查！", view: self.view)
            sender.state = .off
            return
        }
        
        isSendEmail = true
        syncEmailsString = emailsString
        
    }
    
    @IBAction func clickedManualSyncBtn(_ sender: NSButton) {
        manualSyncBtn.tag = 2
        //handleAccountLogin(sender)
    }
    
    
//    func handleAccountLogin(_ sender: NSButton, _ retry: Int = 2) {
//        errorsList = []
//        results = [:]
//        sender.isEnabled = false
//        let tips = "【提示】可能网络原因导致检查失败，所以，自动任务仍在运行。"
//
//        // 测试，清cookie，模拟过期的场景
////        ARNetSession.default.config.httpCookieStorage?.cookies?.forEach({ cookie in
////            print(cookie)
////            if cookie.name == "myacinfo" || cookie.name == "itctx" {
////                ARNetSession.default.config.httpCookieStorage?.deleteCookie(cookie)
////            }
////        })
//
//        // 保存 csv 文件的时间路径
//        let dateFormatter : DateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
//        let currentDate = dateFormatter.string(from: Date())
//        dataPath = currentDate
//        debugPrint(currentDate)
//
//        // 先检查，当前 Session 是否还有效
//        ARNet.check_session.request(successedHandler: { [weak self] result, response in
//            // 未过期，请求数据
//            self?.saveLogs("cookie 未过期，直接请求账号数据。")
//            self?.startAccountNotification(sender: sender, currentDateString: currentDate, ephemeralSession: ARBackgroundSession())
//        }, failedHandler: { [weak self] error, response in
//            debugPrint(error ?? "")
//            let code = response?.statusCode
//            switch code {
//            case 401:
//                debugPrint("session已经过期，重新登陆！")
//                self?.saveLogs("session已经过期，重新登陆中...")
//                // 如果静默登陆成功，则继续，否则邮件通知
//                let account = UserCenter.shared.loginedUser.appleid
//                let password = UserCenter.shared.loginedUser.password
//                guard account.count > 0, password.count > 0 else {
//                    return
//                }
//                // 重新登陆账号
//                ARNet.signin_setup(account: account, password: password).request(successedHandler: {  [weak self] (body, response)  in
//                    let code = response?.statusCode
//                    self?.saveLogs("重新登陆账号，code：\(string(from: code))")
//                    switch code {
//                    case 200:
//                        HUDHelper.shared().loading(currentView())
//                        // 更新 Session
//                        ARNet.login_session.request { (body, response) in
//                            HUDHelper.shared().hideLoading()
//                            let code = response?.statusCode
//                            self?.saveLogs("静默登陆账号成功，code：\(string(from: code))")
//                            // 静默登陆账号成功，继续
//                            switch code {
//                            case 200, 201:
//                                self?.startAccountNotification(sender: sender, currentDateString: currentDate, ephemeralSession: ARBackgroundSession())
//                            default:
//                                if retry > 0 {
//                                    self?.handleAccountLogin(sender, retry - 1)
//                                    return
//                                }
//                                let errors = dictionaryArray(body["serviceErrors"])
//                                let msg = string(from: errors.first?["message"])
//                                HUDHelper.shared().hide(withMessage: msg, in: currentView())
//                                self?.faileSessionHandle(sender: sender, subTitle: "静默登陆账号失败", logs: ["错误码：\(string(from: response?.statusCode))", "Session Error: \(msg)"], stop: true)
//                            }
//                        } failedHandler: { error, response in
//                            HUDHelper.shared().hideLoading()
//                            if let code = response?.statusCode, code != 401, retry > 0 {
//                                self?.handleAccountLogin(sender, retry - 1)
//                                return
//                            }
//                            self?.faileSessionHandle(sender: sender, subTitle: "静默登陆账号失败", logs: [tips, "错误码：\(string(from: response?.statusCode))", "Session Response Error: \(String(describing: error))"])
//                        }
//                    default:
//                        // 409 需要双重验证
//                        // 412 需要升级双重认证
//                        // 401 Apple ID 或密码不正确
//                        self?.faileSessionHandle(sender: sender, text: "账号登陆状态[失效]，需要双重验证，请重新登陆账号！", title: "账号登陆状态[失效]", subTitle: "静默登陆账号失败", logs: ["错误码：\(string(from: response?.statusCode))", "参考错误码: 409表示需要双重验证。", "【操作建议】请在后台重启App并重新登陆苹果账号~"], stop: true)
//                    }
//                }, failedHandler: { [weak self] error, response in
//                    if let code = response?.statusCode, code != 401, retry > 0 {
//                        self?.handleAccountLogin(sender, retry - 1)
//                        return
//                    }
//                    self?.faileSessionHandle(sender: sender, subTitle: "静默登陆账号失败", logs: [tips, "错误码：\(string(from:  response?.statusCode))", "Error: \(String(describing: error))"])
//                })
//            default:
//                if retry > 0 {
//                    self?.handleAccountLogin(sender, retry - 1)
//                    return
//                }
//                self?.faileSessionHandle(sender: sender, logs: [tips, "错误码：\(string(from:  response?.statusCode))", "Error: \(String(describing: error))"])
//            }
//        })
//    }
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "App设置"
        setupUI()
    }
    
    func setupUI() {
        trusDeviceBtn.state = InfoCenter.shared.trusDevice ? .on : .off
        timingSyncBtn.state = TimerUtils.shard.isValidNotificationTimer() ? .on : .off
        syncHoursTF.stringValue = syncHourString
        syncMinutesTF.stringValue = syncMinuteString
        emailSyncBtn.state = isSendEmail ? .on : .off
        notiEmailsTF.stringValue = syncEmailsString
    }
}


extension APSettingVC {
    
    func faileSessionHandle(sender: NSButton, text: String = "账号自动登陆状态[错误]", title: String = "账号自动登陆状态[错误]", subTitle: String = "检查账号状态失败", logs: [String], stop: Bool = false) {
        // 失败处理
        sender.isEnabled = true
        saveLogs("‼️ login error: \(text) \(logs.debugDescription)")
        sendEmailSync(title: title, subTitle: subTitle, logs: logs, stop: stop)
    }
    
//    func startAccountNotification(sender: NSButton, currentDateString: String, ephemeralSession: ARBackgroundSession) {
//        // 串行队列，同步任务
//        let group = DispatchGroup()
//
//        // 获取所有账号，然后在读取账号的消息
//        var accounts = [[String:String]]()
//        if let providers = UserCenter.shared.account_session["availableProviders"] as? [[String: Any]] {
//            providers.forEach { provider in
//                let name = provider["name"] as! String
//                let providerId = String(provider["providerId"] as! Int)
//                accounts.append(["name": name, "id": providerId])
//            }
//        }
//
//        debugPrint(accounts)
//
//        feacth_loop_data(ephemeralSession: ephemeralSession, providers: accounts, group: group)
//
//        group.notify(queue: .main) { [weak self] in
//            self?.saveLogs("✅ 完成所有账号消息检查~ 🎉")
//            self?.successCheckHandle()
//            sender.isEnabled = true
//        }
//
//    }
//
//    func feacth_loop_data(ephemeralSession: ARBackgroundSession, providers: [[String:String]], group: DispatchGroup, index: Int = 0) {
//        group.enter()
//        let group2 = DispatchGroup()
//        let providerId = providers[index]["id"]!
//        let providername = providers[index]["name"]!
//        featch_account_data(ephemeralSession: ephemeralSession, providerId: providerId, providername: providername, group: group2)
//        group2.notify(queue: .main) { [weak self] in
//            self?.saveLogs("完成账号【\(providername)】所有数据处理~")
//            if providers.count <= (index + 1) {
//                group.leave()
//                return
//            }
//            self?.feacth_loop_data(ephemeralSession: ephemeralSession, providers: providers, group: group, index: index + 1)
//            group.leave()
//        }
//    }
//
//    func featch_account_data(ephemeralSession: ARBackgroundSession, providerId: String, providername: String, group: DispatchGroup) {
//        group.enter()
//        ARNet.switch_account(providerId: providerId).bgRequest(ephemeralSession: ephemeralSession, successedHandler: { [weak self] jsonData, response in
//            let group2 = DispatchGroup()
//            self?.saveLogs("开始读取账号【\(providername)】消息~")
//            self?.feactch_message(ephemeralSession: ephemeralSession, providername: providername, group: group2)
//            group2.notify(queue: .main) {
//                group.leave()
//            }
//        }, failedHandler: { [weak self] error, response in
//            self?.saveLogs("❌ 切换账号失败: error：\(String(describing: error))，response：\(response.debugDescription)")
//            if let code = response?.statusCode, code != 401 {
//                self?.saveLogs("❌ 切换账号: \(providername)(\(providerId)) 失败~ 无法读取账号的新消息。(code:\(code))", error: true)
//            } else {
//                self?.saveLogs("❌ 切换账号失败: \(providername)(\(providerId)) ，自动尝试重新登陆中~", error: true)
//            }
//            group.leave()
//        })
//
//    }
//
//    func feactch_message(ephemeralSession: ARBackgroundSession, providername: String, group: DispatchGroup) {
//        group.enter()
//        ARNet.provider_news.bgRequest(ephemeralSession: ephemeralSession) { [weak self] result, response in
//            let data = result["data"]! as! [Any]
//            if var dict = self?.results[providername] {
//                dict["news"] = data
//                self?.results[providername] = dict
//            } else {
//                self?.results[providername] = ["news": data]
//            }
//            self?.saveLogs("获取账号新闻消息数据：\(providername)：\(data.unicodeDescription)")
//            group.leave()
//        } failedHandler: { [weak self] error, response in
//            self?.saveLogs("❌ 获取账号新闻消息失败：\(providername)。status:\(string(from: response?.statusCode)), error:\(String(describing: error))", error: true)
//            group.leave()
//        }
//
//
//        group.enter()
//        ARNet.contract_message.bgRequest(ephemeralSession: ephemeralSession) { [weak self] result, response in
//            let data = result["data"]! as! [Any]
//            if var dict = self?.results[providername] {
//                dict["message"] = data
//                self?.results[providername] = dict
//            } else {
//                self?.results[providername] = ["message": data]
//            }
//            self?.saveLogs("获取账号协议消息数据：\(providername)：\(data.unicodeDescription)")
//            group.leave()
//        } failedHandler: { [weak self] error, response in
//            self?.saveLogs("❌ 获取账号协议消息失败：\(providername)。status:\(string(from: response?.statusCode)), error:\(String(describing: error))", error: true)
//            group.leave()
//        }
//    }
    
    
    func successCheckHandle() {
        // 判断是否为“切换账号失败:”，如果是重新请求
        let retry = manualSyncBtn.tag
        if errorsList.contains(where: { $0.contains("切换账号失败:") }), retry > 0 {
            clickedManualSyncBtn(manualSyncBtn)
            manualSyncBtn.tag = retry - 1
            return
        }
        
        let overTime = 2592000 // 一个月
        let currentTime = Int(Date().timeIntervalSince1970)
        var alls = [String]()
        // 取消新数据
        results.forEach { account,value in
            // 对比是否为新消息，并保存
            let news = value["news"]! //开发者新闻
            let messages = value["message"]! //协议消息
            // 如果新闻不为空，才读取
            alls += getNewMsg(title: "开发者新闻：", news: news, account: account, currentTime: currentTime, overTime: overTime)
            alls += getNewMsg(title: "协议消息：", news: messages, account: account, currentTime: currentTime, overTime: overTime)
        }
        
        var title = "苹果账号消息通知[新消息]"
        if alls.count == 0 {
            title = "苹果账号消息通知[错误]"
        }
        
        // 错误时，发邮件
        if errorsList.count > 0 {
            alls.append("【错误日志】")
            alls += errorsList
        }
        
        // 有新消息
        if alls.count > 0 {
            sendEmailSync(title:title, logs:alls)
        } else {
            self.saveLogs("无新消息，不发送邮件~")
        }
    }
    
    
    func getNewMsg(title: String, news: [Any], account: String, currentTime: Int, overTime: Int) -> [String] {
        var newMsg = [String]()
        newMsg.append("<strong>账号：\(account)</strong>")
        if news.isNotEmpty {
            newMsg.append(title)
            news.forEach { newData in
                if var new = newData as? [String:Any], let subject = new["subject"] as? String, let message = new["message"] as? String  {
                    // 数据库中存在相当的条目，判断时间是否超过一个月，如果超过，再次提示
                    if var oldData = messagesDB[account] as? [String: [String:Any]] {
                        //条目存在，但消息超过一个月，重新认定为新消息，并覆盖
                        if let oldSub = oldData[subject], let oldMessage = oldSub["message"] as? String, let oldDate = oldSub["date"] as? Int {
                            if message != oldMessage || (message == oldMessage && (currentTime - oldDate) > overTime) {
                                //消息内容不相同，或者 消息超过一个月，更新时间并覆盖
                                newMsg.append("《\(subject)》")
                                newMsg.append(message)
                                new["date"] = currentTime
                                oldData[subject] = new
                                messagesDB[account] = oldData
                            }
                        } else {
                            //条目不存在数据库中，新消息
                            newMsg.append("《\(subject)》")
                            newMsg.append(message)
                            new["date"] = currentTime
                            oldData[subject] = new
                            messagesDB[account] = oldData
                        }
                        
                    } else {
                        // 数据库没有这个账号的消息，新消息直接加入
                        newMsg.append("《\(subject)》")
                        newMsg.append(message)
                        new["date"] = currentTime
                        messagesDB[account] = [subject:new]
                    }
                }
            }
        }
        
        newMsg.append("")
        return newMsg.count > 3 ? newMsg : []
    }
    
    
    
    func sendEmailSync(title: String = "苹果账号消息通知[新消息]", subTitle: String = "苹果账号新消息", logs: [String], stop: Bool = false) {
        guard isSendEmail else {
            return
        }
        // 收件人
        let allEmails = syncEmailsString.components(separatedBy: [";", "；", ",", "，"]).filter({!$0.isEmpty})
        let emails = allEmails.filter({ isEmailValid($0) })
        guard emails.count > 0 else {
            saveLogs("同步通知的邮箱地址格式错误！")
            return
        }
        // 邮件内容
        let path = commonPath.path
        var lis = logs.map({ $0.isEmpty ? "<br/>" : "<li>" + $0.replacingOccurrences(of: path, with: "") + "</li>" })
        lis = lis.map({ $0.replacingOccurrences(of: "ref=\"/", with: "href=\"https://appstoreconnect.apple.com/") })
        lis = lis.map({ $0.replacingOccurrences(of: "href='/", with: "href='https://appstoreconnect.apple.com/") })
        lis = lis.map({ $0.replacingOccurrences(of: "_self", with: "_blank") })
        lis = lis.map({ $0.replacingOccurrences(of: "<a href", with: "<a target='_blank' href") })
        let resultHTML = "<ul>" + lis.joined(separator: "") + "</ul>"
        let htmlFile = Bundle.main.path(forResource:"AutoSendEmailTemplate", ofType: "html")
        let htmlString = try? String(contentsOfFile: htmlFile!, encoding: String.Encoding.utf8)
        var html = htmlString?.replacingOccurrences(of: "{{report_title}}", with: subTitle)
        html = html?.replacingOccurrences(of: "{{report_result}}", with: resultHTML)
        //debugPrint(html)
        
        // 发送邮件
        EmailUtils.autoSend(subject: "AppleParty — \(title)", recipients: emails, htmlContent: html!, retry: 3) { [weak self] error in
            debugPrint(error as Any)
            if (error != nil) {
                self?.saveLogs("同步通知邮箱发送审失败：\(String(describing: error))")
            } else {
                self?.saveLogs("同步通知邮箱发送成功~")
            }
        }
        
        if stop == true {
            print("停止定时任务")
            TimerUtils.shard.invalidateNotificationTimer()
            
        }
    }
    
    
    func createFileDirectory(url: URL) {
        let fm = FileManager.default
        let directory = url.deletingLastPathComponent()
        var isDirectory: ObjCBool = false
        // 保证目录存在，不存在就创建目录
        if !(fm.fileExists(atPath: directory.path, isDirectory: &isDirectory) && isDirectory.boolValue) {
            do {
                try fm.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                saveLogs("‼️ create Directory file error:\(error)")
            }
        }
    }
    
    func saveLogs(_ log: String, error: Bool = false, retry: Int = 3) {
        let dateFormatter : DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "[MM-dd HH:mm:ss] "
        let currentDateString = dateFormatter.string(from: Date())
        let out = currentDateString + log
        
        if error {
            errorsList.append(out)
        }
        
        debugPrint(out)
        
        let path = logFilePath
        do {
            try out.appendLine(to: path)
        } catch {
            if retry > 0 {
                saveLogs("‼️ retry save logs file~ error:\(error)", retry: retry - 1)
                saveLogs(log, retry: retry - 1)
            }
        }
    }
    
}
