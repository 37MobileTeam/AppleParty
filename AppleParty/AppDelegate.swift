//
//  AppDelegate.swift
//  AppleParty
//
//  Created by HTC on 2022/3/10.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import Cocoa
import Sparkle

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var mainWindow: NSWindow?
    @IBOutlet weak var updaterController: SPUStandardUpdaterController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // 后台检查更新
        updaterController.updater.checkForUpdatesInBackground()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    /// 当关闭最后一个窗口时，退出app
    /// - Parameter sender:
    /// - Returns: true-窗口程序两者都关闭，false-只关闭窗口
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
    
    /// 应用窗口重新打开时
    ///
    /// - Parameters:
    ///   - sender:
    ///   - flag:
    /// - Returns:
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }

}

