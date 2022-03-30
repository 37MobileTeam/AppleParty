//
//  QrcodeUtil.h
//
//  Created by HTC on 2019/11/25.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

NSDictionary* scanQRCodeOnScreen();

NSImage* createQRImage(NSString *string, NSSize size);

NS_ASSUME_NONNULL_END
