//
//  UIExtension.swift
//  AppleParty
//
//  Created by HTC on 2022/3/12.
//  Copyright © 2022 37 Mobile Games. All rights reserved.
//

import AppKit
import Foundation


extension NSAlert {
    
    static func show(_ content: String, title: String = "提示") {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = content
        alert.runModal()
    }
}


extension NSImageView {
    func showWebImage(_ url: URL) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = NSImage(data: data)
                else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    
    func showWebImage(_ link: String) {
        guard let url = URL(string: link) else { return }
        showWebImage(url)
    }
}
