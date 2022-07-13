//
//  APAppListVC.swift
//  AppleParty
//
//  Created by HTC on 2022/3/17.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa

class APAppListVC: NSViewController {

    fileprivate var adapter: APAppListAdapter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        fetchAppList()
    }
    
    /// 配置显示的功能列表
    func configureCollectionView() {
        let colview = APCollectionView()
        colview.configure(superView: view)
        adapter = APAppListAdapter(collectionView: colview.collectionView)
        adapter?.purchseHandle = { [weak self] app in
            let sb = NSStoryboard(name: "APInAppPurchseVC", bundle: nil)
            let wc = sb.instantiateController(withIdentifier: "APInAppPurchseVC") as! NSWindowController
            let vc = wc.contentViewController as! APInAppPurchseVC
            vc.currentApp = app
            wc.showWindow(self)
        }
        adapter?.screenshotHandle = { [weak self] app in
            let sb = NSStoryboard(name: "ScreenShotUpload", bundle: nil)
            let wc = sb.instantiateController(withIdentifier: "ScreenShotUploadVC") as! NSWindowController
            let vc = wc.contentViewController as! ScreenShotUploadVC
            vc.currentApp = app
            wc.showWindow(self)
        }
    }
    
}


// MARK: - 网络请求
extension APAppListVC {
    
    func fetchAppList() {
        APClient.appList(status: .filter(nil)).request(showLoading: true, inView: self.view) { [weak self] result, response, error in
            guard let err = error else {
                let gamelist = AppList(body: result)
                self?.adapter?.set(items: gamelist.games)
                return
            }
            APHUD.hide(message: err.localizedDescription)
        }
    }
}
