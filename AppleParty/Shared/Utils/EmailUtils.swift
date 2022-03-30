//
//  EmailUtils.swift
//  AppleParty
//
//  Created by HTC on 2021/9/09.
//  Copyright © 2021 37 Mobile Games. All rights reserved.
//

import AppKit
import Foundation
import SwiftSMTP


class EmailUtils: NSObject {
    static func performSend(subject: String, recipients: [String], items: [Any]) {
        let service = NSSharingService(named: NSSharingService.Name.composeEmail)!
        service.recipients = recipients
        service.subject = subject
        service.perform(withItems: items)
    }
    
    static func autoSend(subject: String, recipients: [String], htmlContent: String, _ textContent: String = "", attachmentPath: String = "", config: EamilConfigs, retry: Int = 3, completion: ((Error?) -> Void)? = nil) {
        autoSendAtts(subject: subject, recipients: recipients, htmlContent: htmlContent, textContent, attachmentFiles: [attachmentPath], config: config, retry: retry, completion: completion)
    }
    
    static func autoSendAtts(subject: String, recipients: [String], htmlContent: String, _ textContent: String = "", attachmentFiles: Array<String> = [], config: EamilConfigs, retry: Int = 3, completion: ((Error?) -> Void)? = nil) {
        
        let smtp = SMTP(
            hostname: config.smtp,     // SMTP server address
            email: config.addr,   // username to login
            password: config.pwd       // password to login
        )
        
        let drLight = Mail.User(name: config.name, email: config.addr)
        var megamans = [Mail.User]()
        for email in recipients {
            let megaman = Mail.User(name: "", email: email)
            megamans.append(megaman)
        }
        // Create an HTML `Attachment`
        let htmlAttachment = Attachment(
            htmlContent: htmlContent
            // To reference `fileAttachment`
        )
        
        var attachments: [Attachment] = []
        attachments.append(htmlAttachment)
        
        // Create a file `Attachment`
        attachmentFiles.forEach { filePath in
            if !filePath.isEmpty {
                let fileAttachment = Attachment(filePath: filePath)
                attachments.append(fileAttachment)
            }
        }
        
        let mail = Mail(
            from: drLight,
            to: megamans,
            subject: subject,
            text: textContent,
            attachments: attachments
        )
        
        smtp.send(mail) { (error) in
            if let error = error {
                print("SendEmail error: \(error)")
                if retry > 0 {
                    autoSendAtts(subject: subject, recipients: recipients, htmlContent: htmlContent, textContent, attachmentFiles: attachmentFiles, config: config, retry: retry - 1, completion: completion)
                    return
                }
            }
            debugPrint("email success~")
            if let block = completion {
                block(error)
            }
        }
    }
}
