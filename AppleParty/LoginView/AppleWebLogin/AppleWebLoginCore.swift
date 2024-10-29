//
//  AppleWebLoginCore.swift
//  AppleWebLogin
//
//  Created by 秋星桥 on 2024/10/23.
// ref: https://github.com/Lakr233/AppleWebLogin

import Combine
@preconcurrency import WebKit

//private let loginURL = URL(string: "https://account.apple.com/sign-in")!
private let loginURL = URL(string: "https://appstoreconnect.apple.com/login")!

public class AppleWebLoginCore: NSObject, WKUIDelegate, WKNavigationDelegate {
    var webView: WKWebView {
        associatedWebView
    }

    private let associatedWebView: WKWebView
    private var dataPopulationTimer: Timer? = nil
    private var firstLoadComplete = false

    public private(set) var onFirstLoadComplete: (() -> Void)?
    public var onCredentialPopulation: ((String, [HTTPCookie]) -> Void)?

    override public init() {
        let contentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.userContentController = contentController
        configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        configuration.websiteDataStore = .nonPersistent()

        associatedWebView = .init(
            frame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            configuration: configuration
        )
        associatedWebView.isHidden = true

        super.init()

        associatedWebView.uiDelegate = self
        associatedWebView.navigationDelegate = self

        associatedWebView.load(.init(url: loginURL))

        #if DEBUG
            if associatedWebView.responds(to: Selector(("setInspectable:"))) {
                associatedWebView.perform(Selector(("setInspectable:")), with: true)
            }
        #endif

        let dataPopulationTimer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            removeUnwantedElements()
            populateData()
        }
        RunLoop.main.add(dataPopulationTimer, forMode: .common)
        self.dataPopulationTimer = dataPopulationTimer
    }

    deinit {
        dataPopulationTimer?.invalidate()
        onCredentialPopulation = nil
    }

    public func webView(_: WKWebView, didFinish _: WKNavigation!) {
        guard !firstLoadComplete else { return }
        defer { firstLoadComplete = true }
        associatedWebView.isHidden = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onFirstLoadComplete?()
            self.onFirstLoadComplete = nil
        }
    }
    
//    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping @MainActor (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
//        let request = navigationAction.request
//        if let headers = request.allHTTPHeaderFields {
//            print(request.url?.absoluteString)
//            print("headers: \(headers)")
//            if let scntValue = headers["scnt"] {
//                print("scnt value: \(scntValue)")
//            }
//        }
//        decisionHandler(.allow, preferences)
//    }

    public func installFirstLoadCompleteTrap(_ block: @escaping () -> Void) {
        onFirstLoadComplete = block
    }

    public func installCredentialPopulationTrap(_ block: @escaping (String, [HTTPCookie]) -> Void) {
        onCredentialPopulation = block
    }

    private func removeUnwantedElements() {
        let removeElements = """
        Element.prototype.remove = function() {
            this.parentElement.removeChild(this);
        }
        NodeList.prototype.remove = HTMLCollection.prototype.remove = function() {
            for(var i = this.length - 1; i >= 0; i--) {
                if(this[i] && this[i].parentElement) {
                    this[i].parentElement.removeChild(this[i]);
                }
            }
        }
        document.getElementById("header").remove();
        document.getElementsByClassName('landing__animation').remove();
        """
        associatedWebView.evaluateJavaScript(removeElements) { _, _ in
        }
    }

    private func populateData() {
        guard let onCredentialPopulation else { return }
        associatedWebView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            //print(cookies)
            for cookie in cookies where cookie.name == "myacinfo" {
                let value = cookie.value
                onCredentialPopulation(value, cookies)
                self.onCredentialPopulation = nil
            }
        }
    }
}
