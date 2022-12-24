//
//  ScreenShotUploadVC.swift
//  AppleParty
//
//  Created by HTC on 2022/2/25.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa
import AVFoundation

enum ScreenShotType: Int {
    case iOS5_5 = 0 //iPhone 5.5 英寸显示屏
    case iOS6_5 = 1 //iPhone 6.5 英寸显示屏
    case iPad_Pro = 2 //iPad Pro 12.9 英寸显示屏
}

class ScreenShotUploadVC: NSViewController {
    
    public var currentApp: App? {
        didSet {
            fetchAppInfo()
            fetchAppVersionData()
        }
    }
    public var appInfo: AppInfo?
    
    @IBOutlet weak var appName: NSTextField!
    @IBOutlet weak var appSKU: NSTextField!
    @IBOutlet weak var appleID: NSTextField!
    @IBOutlet weak var localButton: NSPopUpButton!
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var tips_title: NSTextField!
    @IBOutlet weak var tips_count: NSTextField!
    @IBOutlet weak var tips_desc: NSTextField!
    
    private var selectTag = 0
    private var filesData = [[[String:String]]](repeating: [[String:String]](), count: 3)
    
    private let imageTypes = ["jpg", "jpeg", "png", "JPG", "JPEG", "PNG"]
    private let videoTypes = ["mov", "m4v", "mp4", "MOV", "M4V", "MP4"]
    private let locales = ["zh-Hans", "zh-Hant", "ko", "ja"]
    
    private let imageSizes = ["0": ["1242x2208", "2208x1242"],
                              "1": ["1242x2688", "2688x1242"],
                              "2": ["2048x2732", "2732x2048"]]
    
    private let videoSizes = ["0": ["1080x1920", "1920x1080"],
                              "1": ["886x1920", "1920x886"],
                              "2": ["1200x1600", "1600x1200"]]
    
    private var app_name = ""
    private var app_version = ""
    private var uploadModel = XMLModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    func setupView() {
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.selectionHighlightStyle = .none
              
        localButton.removeAllItems()
        for locale in locales {
            localButton.addItem(withTitle: locale)
        }
        localButton.selectItem(at: 0)
        
        let teamId = UserCenter.shared.developerTeamId
        if teamId.isEmpty {
            fetchAccountTeamInfo()
        } else {
            appleID.stringValue = "Team ID: " + UserCenter.shared.developerTeamId
        }
    }
    
    @IBAction func clickedUploadButton(_ sender: NSButton) {
        
        guard filesData.filter({ $0.count > 0 }).count > 0 else  {
            APHUD.hide(message: "图片或视频不能为空！", view: self.view, delayTime: 1)
            return
        }
        
        guard app_name.count > 0, app_version.count > 0 else {
            APHUD.hide(message: "应用名和版本获取失败！请刷新重试~", view: self.view, delayTime: 1)
            return
        }
        
        guard let sp = UserCenter.shared.currentSPassword else {
            let vc = APSPasswordSettingVC()
            vc.updateCompletion = { [weak self] spassword in
                if let sp = spassword  {
                    self?.uploadData(sp)
                }
            }
            presentAsSheet(vc)
            return
        }
        
        uploadData(sp)
    }
    
    @IBAction func reloadAppData(_ sender: Any) {
        fetchAppVersionData()
    }
    
    @IBAction func clickedHelp(_ sender: NSButton) {
        let vc = ScreenShotHelpPopoverVC()
        self.present(vc, asPopoverRelativeTo: sender.frame, of: self.view, preferredEdge: .maxX, behavior:.transient)
    }
    
    
    @IBAction func changeSegmentedControl(_ sender: NSSegmentedControl) {
        selectTag = sender.selectedTag()
        reloadTableView(ScreenShotType.init(rawValue: selectTag) ?? .iOS5_5)
    }
    
    @IBAction func uploadFiles(_ sender: NSButton) {
        
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = true
        openPanel.allowedFileTypes = imageTypes + videoTypes
        
        openPanel.beginSheetModal(for: self.view.window!) { [self] (modalResponse) in
            if modalResponse == .OK {
                handleAutoImages(openPanel.urls)
            }
        }
    }
    
}

// MARK: - 网络请求
extension ScreenShotUploadVC {
    
    func fetchAccountTeamInfo() {
        // 获取开发者 Team id 信息
        APClient.ascProvider.request { [weak self] result, response, error in
            guard let err = error else {
                self?.appleID.stringValue = "Team ID: " + UserCenter.shared.developerTeamId
                return
            }
            APHUD.hide(message: err.localizedDescription, delayTime: 2)
        }
    }
    
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
            self?.appSKU.stringValue = "App SKU: \(info.sku)"
        }
        
    }
    
    func fetchAppVersionData(_ replay: Int = 3) {
        
        guard let appid = currentApp?.appId else {
            APHUD.hide(message: "当前 App 的 appleid 为空！", delayTime: 1)
            return
        }
        
        APClient.appVersion(appid: appid).request { [weak self] data, response, error in
            
            if let err = error {
                if replay > 0 {
                    self?.fetchAppVersionData(replay-1)
                } else {
                    NSAlert.show(err.localizedDescription)
                }
                return
            }
            
            let data = data["data"] as? [String: Any]
            var dict = [String: Any]()
            if let data = data, let platforms = data["platforms"] as? [[String: Any]] {
                platforms.forEach { pf in
                    let platformString = pf["platformString"] as! String
                    dict[platformString] = pf
                }
            }
            
            guard let ios = dict["ios"] as? [String: Any], let inFlightVersion = ios["inFlightVersion"] as? [String: Any] else {
                NSAlert.show("当前 App 无待送审的版本，请检查确认！")
                return
            }
            
            self?.app_version = inFlightVersion["version"] as! String
            
            if let data = data, let titles = data["localizedMetadata"] as? [[String: Any]] {
                if titles.count > 0 {
                    // 这里只读取第一个
                    self?.app_name = titles[0]["name"] as! String
                }
            }
            
            DispatchQueue.main.async { [self] in
                self?.appName.stringValue = "App Name: \(self!.app_name) (\(self!.app_version))"
            }
            
        }
    }
}


// MARK: - NSTableViewDelegate
extension ScreenShotUploadVC: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filesData[selectTag].count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var data = filesData[selectTag][row]
        let isImg = data["type"]! == "1"
        
        switch tableColumn!.identifier.rawValue {
        case "review":
            let imgView = NSImageView()
            if let imageRef = NSImage(byReferencingFile: data["url"]!) {
                imgView.image = imageRef
            }
            if !isImg {
                let url = URL(fileURLWithPath: data["url"]!)
                let videoImg = previewImageForLocalVideo(url)
                imgView.image = videoImg
            }
            return imgView
        case "fileName":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "fileName"), owner: self) as? NSTableCellView
            cell?.textField?.stringValue = "\(isImg ? "图片" : "视频")：\n\(data["name"]!)"
            return cell
        case "setting":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "setting"), owner: self) as? ScreenShotUploadCell
            cell?.row = row
            cell?.showVideoView(!isImg)
            cell?.updateData(sort: data["index"] ?? "", frame: data["frame"] ?? "00:00")
            cell?.changeSortIndex = { index, crow in
                data["index"] = index
                self.filesData[self.selectTag][row] = data
            }
            cell?.changeVideoFrame = { frame, crow in
                data["frame"] = frame
                self.filesData[self.selectTag][row] = data
            }
            return cell
        case "operation":
            let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "operation"), owner: self) as? ScreenShotDeleteCell
            cell?.row = row
            cell?.deleteCell = { row in
                self.filesData[self.selectTag].remove(at: row)
                self.tableView.reloadData()
                self.reloadTableView(ScreenShotType(rawValue: self.selectTag) ?? .iOS5_5)
            }
            return cell
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        // macOS 11 以下，如果不能点击，textfield 也不能点击
        return true
    }
}


// MARK: - Upload
extension ScreenShotUploadVC {
    
    func uploadData(_ sp: SPassword) {
        
        APHUD.show(message: "上传中", view: self.view)
        
        let localIndex = localButton.indexOfSelectedItem
        
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            
            uploadModel = XMLModel()
            
            guard let info = appInfo else {
                fetchAppInfo()
                APHUD.hide(message: "加载数据异常，请刷新后重试~")
                return
            }
            
            uploadModel.vendor_id = info.sku
            
            // 获取创建 itms 文件的路径
            let filePath = XMLManager.getShotsPath(currentApp!.appId)
            
            // 先删除旧的文档
            XMLManager.deleteITMS(filePath)
            
            // 数据转模型
            handleDataToModel(localIndex)
            
            uploadModel.createShots(directoryPath: filePath)
            
            let result = XMLManager.uploadITMS(account: sp.account, pwd: sp.password, filePath: filePath)
            
            DispatchQueue.main.async {
                APHUD.hide()
                self.closeSelfAndCallBack(result)
            }
        }
    }
    
    func handleDataToModel(_ localIndex: Int) {
        
        let locale = locales[localIndex]
        uploadModel.app_locale = locale
        uploadModel.app_title = app_name
        uploadModel.app_version = app_version
        
        let iOS5_5 = filesData[0]
        let iOS6_5 = filesData[1]
        let iPad = filesData[2]
    
        //iPhone 5.5 英寸
        let (img5_5, video5_5, set5_5) = getScreenShotModel(iOS5_5)
        uploadModel.shots["iOS-5.5-in"] = img5_5
        uploadModel.videos["iOS-5.5-in"] = video5_5
        
        //iPhone 6.5 英寸
        let (img6_5, video6_5, set6_5) = getScreenShotModel(iOS6_5)
        uploadModel.shots["iOS-6.5-in"] = img6_5
        uploadModel.videos["iOS-6.5-in"] = video6_5
        
        let (imgiPad, videoiPad, setiPad) = getScreenShotModel(iPad)
        //iPad Pro（第2代） 12.9 英寸
        uploadModel.shots["iOS-iPad-Pro"] = imgiPad
        uploadModel.videos["iOS-iPad-Pro"] = videoiPad
        //iPad Pro（第3代） 12.9 英寸
        uploadModel.shots["iOS-iPad-Pro-2018"] = imgiPad
        uploadModel.videos["iOS-iPad-Pro-2018"] = videoiPad
        
        // 图片和视频资源
        let fileURLs = set5_5.union(set6_5).union(setiPad)
        var dict = [String: String]()
        fileURLs.forEach { value in
            value.forEach { dict[$0] = $1 }
        }
        uploadModel.filePaths = dict
    }
    
    func getScreenShotModel(_ shots: [[String: String]]) -> ([Screen_Shot], [Screen_Shot], Set<[String:String]>) {
        var imageList = [Screen_Shot]()
        var videoList = [Screen_Shot]()
        var urlList: Set<[String:String]> = []
        shots.forEach { data in
            let isImg = data["type"]! == "1"
            let url = data["url"] ?? ""
            let kind = data["kind"] ?? ""
            let name = kind + (data["name"] ?? "") //kind+name：避免不同尺寸使用同一个图片名字，导致替换的问题
            let index = data["index"] ?? ""
            let frame = "00:00:" + (data["frame"] ?? "00:00")
            let size = URL.init(fileURLWithPath: url).fileSize()
            let md5 = URL.init(fileURLWithPath: url).fileMD5()
            let item = Screen_Shot(file_name: name, size: size, checksum: md5 ?? "", position: index, preview_time: frame)
            urlList.insert([name: url])
            isImg ? imageList.append(item) : videoList.append(item)
        }
        return (imageList, videoList, urlList)
    }
    
    func closeSelfAndCallBack(_ result: (Int32, String?)) {
        
        if result.0 == 0 {
            NSAlert.show("上传成功！稍后可在苹果后台查看~")
            // 删除旧的文档，避免占用空间过大
            let filePath = XMLManager.getShotsPath(currentApp!.appId)
            XMLManager.deleteITMS(filePath)
        } else {
            let sb = NSStoryboard(name: "APDebugVC", bundle: Bundle(for: self.classForCoder))
            let newWC = sb.instantiateController(withIdentifier: "APDebugWC") as? NSWindowController
            let logVC = newWC?.contentViewController as? APDebugVC
            newWC?.window?.title = "上传错误日志"
            logVC?.debugLog = result.1 ?? ""
            newWC?.showWindow(self)
        }
    }
}

// MARK: - 内部方法
extension ScreenShotUploadVC {
    
    func handleAutoImages(_ files: [URL]) {
        files.forEach { url in
            // 如果是文件夹，则递归
            if url.hasDirectoryPath {
                let urls = subFilesInDirectory(url: url)
                handleAutoImages(urls)
                return
            }
            var size = "0x0"
            var sizes = [String: [String]]()
            var type = "1"
            let fileType = url.pathExtension
            if imageTypes.contains(fileType) {
                let image = NSImage(contentsOf: url)
                guard let rep = image?.representations.first as? NSBitmapImageRep else {
                    return
                }
                size = "\(rep.pixelsWide)x\(rep.pixelsHigh)"
                sizes = imageSizes
                type = "1"
            } else if videoTypes.contains(fileType) {
                guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else {
                    return
                }
                let rep = track.naturalSize.applying(track.preferredTransform)
                size = "\(Int(rep.width))x\(Int(rep.height))"
                sizes = videoSizes
                type = "2"
            }
            
            sizes.forEach { (index: String, value: [String]) in
                if value.contains(size) {
                    // 处理数据
                    var dict = [String: String]()
                    dict["url"] = url.path
                    dict["name"] = url.lastPathComponent
                    dict["type"] = type
                    dict["kind"] = index
                    // 更新数据
                    var value = filesData[Int(index)!]
                    value.append(dict)
                    filesData[Int(index)!] = value
                }
            }
        }
        // 刷新列表
        reloadTableView(ScreenShotType.init(rawValue: selectTag) ?? .iOS5_5)
    }
    
    func subFilesInDirectory(url: URL) -> [URL] {
        var urls = [URL]()
        // 迭代器，包含子目录
        let files = FileManager.default.enumerator(atPath: url.path)
        while let file = files?.nextObject() {
            if let file = file as? String {
                let nextFile = url.appendingPathComponent(file)
                if !nextFile.hasDirectoryPath {
                    urls.append(nextFile)
                }
            }
        }
        return urls
    }
    
    func reloadTableView(_ index: ScreenShotType) {
        let list = filesData[index.rawValue]
        let images = list.filter({ $0["type"] == "1" })
        tips_count.stringValue = "\(list.count - images.count)/3 个 App 预览 | \(images.count)/10 张屏幕快照"
        switch index {
        case .iOS5_5:
            tips_title.stringValue = "iPhone 5.5 英寸显示屏"
            tips_desc.stringValue = "图片：1242 x 2208、2208 x 1242，视频：1080 x 1920、1920 x 1080"
        case .iOS6_5:
            tips_title.stringValue = "iPhone 6.5 英寸显示屏"
            tips_desc.stringValue = "图片：1242 x 2688、2688 x 1242，视频：886 x 1920、1920 x 886"
        case .iPad_Pro:
            tips_title.stringValue = "iPad Pro 12.9 英寸显示屏"
            tips_desc.stringValue = "图片：2048 x 2732、2732 x 2048，视频：1200 x 1600、1600 x 1200"
        }
        
        tableView.reloadData()
    }
    
    func previewImageForLocalVideo(_ url: URL) -> NSImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        var time = asset.duration
        //If possible - take not the first frame (it could be completely black or white on camara's videos)
        time.value = min(time.value, 2)
        do {
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let track = asset.tracks(withMediaType: AVMediaType.video).first
            let rep = track?.naturalSize.applying(track?.preferredTransform ?? CGAffineTransform())
            return NSImage(cgImage: imageRef, size: NSSize(width: rep?.width ?? 120, height: rep?.height ?? 60))
        }
        catch let error as NSError
        {
            print("Image generation failed with error \(error)")
            return nil
        }
    }
}
