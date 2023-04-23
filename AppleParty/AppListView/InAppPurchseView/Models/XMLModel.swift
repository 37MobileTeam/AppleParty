//
//  XMLModel.swift
//  AppleParty
//
//  Created by 易承 on 2021/5/26.
//

import Foundation
import SWXMLHash


struct In_App_Purchase {
    
    var product_id = ""             // 商品id
    var reference_name = ""         // 商品名称
    var type: InAppPurchaseType = .UNKNOW    // 商品类型
    var wholesale_price_tier = 0    // 价格等级
    var title = ""                  // 本地化title
    var description = ""            // 本地化描述
    var file_name = ""              // 截图文件名
    var size = ""                   // 截图大小
    var checksum = ""               // 截图md5
    var review_notes = ""           // 商品描述
    var lang = "zh-Hans"            // 本地化语言
    
    var inputPrice = ""             // 表格的价格
}

struct Screen_Shot {
    var file_name = ""              // 文件名
    var size = ""                   // 大小
    var checksum = ""               // md5
    var position = "0"              // 位置
    var preview_time = "00:00:05:00" //设置默认视频时间节点
}

struct XMLModel {
    var provider = UserCenter.shared.developerTeamId               // 公司名称
    var team_id = UserCenter.shared.developerTeamId                // 开发者teamid
    var vendor_id = ""                                             // sku 套装id
    
    // 内购品项
    var iaps: [In_App_Purchase] = []
    
    // 商店截图
    var app_locale = "zh-Hans"    // 本地化语言
    var app_platform = "ios"  // ios 或 osx
    var app_version = "" //当前版本
    var app_title = "" //商店应用名
    var shots: [String: [Screen_Shot]] = [:]
    var videos: [String: [Screen_Shot]] = [:]
    
    // 上传ipa文件
    var apple_id = "" // apple id
    var archive_type = "bundle" //上传文件类型
    var ipa_name = "ipa.ipa" //默认包名
    var ipa_size = ""
    var ipa_md5 = ""
    
    // 需要复制的文件 [fileName: fileURL]
    var filePaths: [String: String] = [:]
    
    func createIAP(directoryPath: String) {
        // 根标签
        let root = GDataXMLNode.element(withName: "package")
        // package属性
        let version = GDataXMLNode.attribute(withName: "version", stringValue: "software5.11") as? GDataXMLNode
        let xmlns = GDataXMLNode.attribute(withName: "xmlns", stringValue: "http://apple.com/itunes/importer") as? GDataXMLNode
        root?.addAttribute(version)
        root?.addAttribute(xmlns)
        // provider\team_id
        let pro = GDataXMLNode.element(withName: "provider", stringValue: provider)
        let tid = GDataXMLNode.element(withName: "team_id", stringValue: team_id)
        root?.addChild(pro)
        root?.addChild(tid)
        // software
        // vendor_id
        let software = GDataXMLNode.element(withName: "software")
        let vid = GDataXMLNode.element(withName: "vendor_id", stringValue: vendor_id)
        software?.addChild(vid)
        // software_metadata/in_app_purchases
        let software_metadata = GDataXMLNode.element(withName: "software_metadata")
        let in_app_purchases = GDataXMLNode.element(withName: "in_app_purchases")
        // in_app_purchase array
        for iap in iaps {
            let in_app_purchase = GDataXMLNode.element(withName: "in_app_purchase")
            // product_id/reference_name/type
            let product_id = GDataXMLNode.element(withName: "product_id", stringValue: iap.product_id)
            let reference_name = GDataXMLNode.element(withName: "reference_name", stringValue: iap.reference_name)
            let type = GDataXMLNode.element(withName: "type", stringValue: iap.type.rawValue)
            // products
            let products = GDataXMLNode.element(withName: "products")
            let product = GDataXMLNode.element(withName: "product")
            let cleared_for_sale = GDataXMLNode.element(withName: "cleared_for_sale", stringValue: "true")
            let wholesale_price_tier = GDataXMLNode.element(withName: "wholesale_price_tier", stringValue: String(iap.wholesale_price_tier))
            product?.addChild(cleared_for_sale)
            product?.addChild(wholesale_price_tier)
            products?.addChild(product)
            // locales
            let locales = GDataXMLNode.element(withName: "locales")
            let locale = GDataXMLNode.element(withName: "locale")
            let name = GDataXMLNode.attribute(withName: "name", stringValue: iap.lang) as? GDataXMLNode
            locale?.addAttribute(name)
            let title = GDataXMLNode.element(withName: "title", stringValue: iap.title)
            let description = GDataXMLNode.element(withName: "description", stringValue: iap.description)
            locale?.addChild(title)
            locale?.addChild(description)
            locales?.addChild(locale)
            // review_screenshot
            let review_screenshot = GDataXMLNode.element(withName: "review_screenshot")
            let file_name = GDataXMLNode.element(withName: "file_name", stringValue: iap.file_name)
            let size = GDataXMLNode.element(withName: "size", stringValue: iap.size)
            let checksum = GDataXMLNode.element(withName: "checksum", stringValue: iap.checksum)
            let checksum_type = GDataXMLNode.attribute(withName: "type", stringValue: "md5") as? GDataXMLNode
            checksum?.addAttribute(checksum_type)
            review_screenshot?.addChild(file_name)
            review_screenshot?.addChild(size)
            review_screenshot?.addChild(checksum)
            // review_notes
            let review_notes = GDataXMLNode.element(withName: "review_notes", stringValue: iap.review_notes)
            // 合并到in_app_purchase
            in_app_purchase?.addChild(product_id)
            in_app_purchase?.addChild(reference_name)
            in_app_purchase?.addChild(type)
            in_app_purchase?.addChild(products)
            in_app_purchase?.addChild(locales)
            in_app_purchase?.addChild(review_screenshot)
            in_app_purchase?.addChild(review_notes)
            in_app_purchases?.addChild(in_app_purchase)
        }
        software_metadata?.addChild(in_app_purchases)
        software?.addChild(software_metadata)
        root?.addChild(software)
        // 生成xml文件
        let xmlDoc = GDataXMLDocument(rootElement: root)
        let data = xmlDoc?.xmlData()
//        let xmlString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        // 保存文件
        // 创建文件夹
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription);
            }
        }
        // 创建文件
        let filePath = directoryPath + "/metadata.xml"
        debugPrint(filePath)
        if !FileManager.default.fileExists(atPath: filePath) {
            FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
        }else {
            try? FileManager.default.removeItem(atPath: filePath)
            FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
        }
        
        for name in filePaths.keys {
            let path = filePaths[name] ?? ""
            try? FileManager.default.copyItem(atPath: path, toPath: directoryPath + "/" + name)
        }
    }
    
    
    func createShots(directoryPath: String) {
        // 根标签
        let root = GDataXMLNode.element(withName: "package")
        // package属性
        let version = GDataXMLNode.attribute(withName: "version", stringValue: "software5.11") as? GDataXMLNode
        let xmlns = GDataXMLNode.attribute(withName: "xmlns", stringValue: "http://apple.com/itunes/importer") as? GDataXMLNode
        root?.addAttribute(version)
        root?.addAttribute(xmlns)
        // provider\team_id
        let pro = GDataXMLNode.element(withName: "provider", stringValue: provider)
        let tid = GDataXMLNode.element(withName: "team_id", stringValue: team_id)
        root?.addChild(pro)
        root?.addChild(tid)
        // software
        // vendor_id
        let software = GDataXMLNode.element(withName: "software")
        let vid = GDataXMLNode.element(withName: "vendor_id", stringValue: vendor_id)
        software?.addChild(vid)
        // software_metadata/in_app_purchases
        let software_metadata = GDataXMLNode.element(withName: "software_metadata")
        let app_platform = GDataXMLNode.attribute(withName: "app_platform", stringValue: app_platform) as? GDataXMLNode
        software_metadata?.addAttribute(app_platform)
        // versions
        let s_versions = GDataXMLNode.element(withName: "versions")
        let s_version = GDataXMLNode.element(withName: "version")
        let app_version = GDataXMLNode.attribute(withName: "string", stringValue: app_version) as? GDataXMLNode
        s_version?.addAttribute(app_version)
        // locales
        let locales = GDataXMLNode.element(withName: "locales")
        let locale = GDataXMLNode.element(withName: "locale")
        let locale_name = GDataXMLNode.attribute(withName: "name", stringValue: app_locale) as? GDataXMLNode
        locale?.addAttribute(locale_name)
        let locale_title = GDataXMLNode.element(withName: "title", stringValue: app_title)
        locale?.addChild(locale_title)
        
        // app_previews
        if videos.filter({ $0.value.count > 0 }).count > 0 {
            let app_previews = GDataXMLNode.element(withName: "app_previews")
            videos.forEach { (key: String, value: [Screen_Shot]) in
                // app_preview
                value.forEach { video in
                    let app_preview = GDataXMLNode.element(withName: "app_preview")
                    // display_target
                    let display_target = GDataXMLNode.attribute(withName: "display_target", stringValue: key) as? GDataXMLNode
                    app_preview?.addAttribute(display_target)
                    let position = GDataXMLNode.attribute(withName: "position", stringValue: video.position) as? GDataXMLNode
                    app_preview?.addAttribute(position)
                    // data_file
                    let data_file = GDataXMLNode.element(withName: "data_file")
                    let file_role = GDataXMLNode.attribute(withName: "role", stringValue: "source") as? GDataXMLNode
                    data_file?.addAttribute(file_role)
                    let file_size = GDataXMLNode.element(withName: "size", stringValue: video.size)
                    data_file?.addChild(file_size)
                    let file_name = GDataXMLNode.element(withName: "file_name", stringValue: video.file_name)
                    data_file?.addChild(file_name)
                    let checksum = GDataXMLNode.element(withName: "checksum", stringValue: video.checksum)
                    data_file?.addChild(checksum)
                    // data_file
                    let preview_image_time = GDataXMLNode.element(withName: "preview_image_time", stringValue: video.preview_time)
                    let preview_format = GDataXMLNode.attribute(withName: "format", stringValue: "30/1:1/nonDrop") as? GDataXMLNode
                    preview_image_time?.addAttribute(preview_format)
                    // 最后添加
                    app_preview?.addChild(data_file)
                    app_preview?.addChild(preview_image_time)
                    app_previews?.addChild(app_preview)
                }
                
            }
            locale?.addChild(app_previews)
        }

        if shots.filter({ $0.value.count > 0 }).count > 0 {
            let app_screenshots = GDataXMLNode.element(withName: "software_screenshots")
            shots.forEach { (key: String, value: [Screen_Shot]) in
                // app_preview
                value.forEach { video in
                    let app_screenshot = GDataXMLNode.element(withName: "software_screenshot")
                    // display_target
                    let display_target = GDataXMLNode.attribute(withName: "display_target", stringValue: key) as? GDataXMLNode
                    app_screenshot?.addAttribute(display_target)
                    let position = GDataXMLNode.attribute(withName: "position", stringValue: video.position) as? GDataXMLNode
                    app_screenshot?.addAttribute(position)
                    // data_file
                    let file_size = GDataXMLNode.element(withName: "size", stringValue: video.size)
                    app_screenshot?.addChild(file_size)
                    let file_name = GDataXMLNode.element(withName: "file_name", stringValue: video.file_name)
                    app_screenshot?.addChild(file_name)
                    let checksum = GDataXMLNode.element(withName: "checksum", stringValue: video.checksum)
                    app_screenshot?.addChild(checksum)
                    let checksum_type = GDataXMLNode.attribute(withName: "type", stringValue: "md5") as? GDataXMLNode
                    checksum?.addAttribute(checksum_type)
                    // 最后添加
                    app_screenshots?.addChild(app_screenshot)
                }
            }
            locale?.addChild(app_screenshots)
        }
        
        locales?.addChild(locale)
        s_version?.addChild(locales)
        s_versions?.addChild(s_version)
        software_metadata?.addChild(s_versions)
        software?.addChild(software_metadata)
        root?.addChild(software)
        
        // 生成xml文件
        let xmlDoc = GDataXMLDocument(rootElement: root)
        let data = xmlDoc?.xmlData()
        //let xmlString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        // 创建文件夹
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription);
            }
        }
        
        // 创建文件
        let filePath = directoryPath + "/metadata.xml"
        debugPrint(filePath)
        if !FileManager.default.fileExists(atPath: filePath) {
            FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
        }else {
            try? FileManager.default.removeItem(atPath: filePath)
            FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
        }
        
        // 文件复制
        for name in filePaths.keys {
            let path = filePaths[name] ?? ""
            try? FileManager.default.copyItem(atPath: path, toPath: directoryPath + "/" + name)
        }
    }
    
    
    func createIpaFile(directoryPath: String) {
        // 根标签
        let root = GDataXMLNode.element(withName: "package")
        // package属性
        let version = GDataXMLNode.attribute(withName: "version", stringValue: "software5.11") as? GDataXMLNode
        let xmlns = GDataXMLNode.attribute(withName: "xmlns", stringValue: "http://apple.com/itunes/importer") as? GDataXMLNode
        root?.addAttribute(version)
        root?.addAttribute(xmlns)
        // software_assets
        let software_assets = GDataXMLNode.element(withName: "software_assets")
        let apple_id = GDataXMLNode.attribute(withName: "apple_id", stringValue: apple_id) as? GDataXMLNode
        let app_platform = GDataXMLNode.attribute(withName: "app_platform", stringValue: app_platform) as? GDataXMLNode
        software_assets?.addAttribute(apple_id)
        software_assets?.addAttribute(app_platform)
        // asset
        let asset = GDataXMLNode.element(withName: "asset")
        let asset_type = GDataXMLNode.attribute(withName: "type", stringValue: archive_type) as? GDataXMLNode
        asset?.addAttribute(asset_type)
        //data_file
        let data_file = GDataXMLNode.element(withName: "data_file")
        let size = GDataXMLNode.element(withName: "size", stringValue: ipa_size)
        let file_name = GDataXMLNode.element(withName: "file_name", stringValue: ipa_name)
        let checksum = GDataXMLNode.element(withName: "checksum", stringValue: ipa_md5)
        let checksum_type = GDataXMLNode.attribute(withName: "type", stringValue: "md5") as? GDataXMLNode
        checksum?.addAttribute(checksum_type)
        // 逆序添加
        data_file?.addChild(size)
        data_file?.addChild(file_name)
        data_file?.addChild(checksum)
        asset?.addChild(data_file)
        software_assets?.addChild(asset)
        root?.addChild(software_assets)
        
        // 生成xml文件
        let xmlDoc = GDataXMLDocument(rootElement: root)
        let data = xmlDoc?.xmlData()
        let xmlString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
        print(xmlString as Any)
        // 创建文件夹
        if !FileManager.default.fileExists(atPath: directoryPath) {
            do {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription);
            }
        }
        
        // 创建文件
        let filePath = directoryPath + "/metadata.xml"
        debugPrint(filePath)
        if !FileManager.default.fileExists(atPath: filePath) {
            FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
        }else {
            try? FileManager.default.removeItem(atPath: filePath)
            FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
        }
        
        // 文件复制
        for name in filePaths.keys {
            let path = filePaths[name] ?? ""
            try? FileManager.default.copyItem(atPath: path, toPath: directoryPath + "/" + name)
        }
        
    }
}
