//
//  APHUD.swift
//  AppleParty
//
//  Created by HTC on 2022/3/18.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa
//import MBProgressHUD_OSX


let APHUD = HUD.shared

class HUD: NSObject {
    
    static let shared = HUD()
    
    private var loadHud: MBProgressHUD?
    private var textHud: MBProgressHUD?
    
    func showLoading(_ view: NSView = currentView()) {
        if loadHud != nil {
            loadHud?.hide(true)
        }
        guard let loadHud = MBProgressHUD(view: view) else {
            return
        }
        self.loadHud = loadHud
        view.addSubview(loadHud)
        loadHud.show(true)
    }
    
    func hideLoading() {
        loadHud?.hide(true)
    }
    
    func show(message: String, view: NSView = currentView()) {
        if textHud != nil {
            textHud?.hide(true)
        }
        guard let textHud = MBProgressHUD(view: view) else {
            return
        }
        self.textHud = textHud
        textHud.labelText = message
        view.addSubview(textHud)
        textHud.show(true)
    }
    
    func hide() {
        textHud?.hide(true)
    }
    
    func hide(message: String, view: NSView = currentView(), delayTime: TimeInterval = 3) {
        guard let hud = MBProgressHUD(view: view) else {
            return
        }
        hud.mode = MBProgressHUDModeText
        hud.labelText = message
        hud.removeFromSuperViewOnHide = true
        view.addSubview(hud)
        hud.show(true)
        hud.hide(true, afterDelay: delayTime)
    }
}
