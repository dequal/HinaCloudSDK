//
// WKWebView+HNBridge.h
// HinaDataSDK
//
// Created by hina on 2022/3/21.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WKWebView (HNBridge)

- (WKNavigation *)hinadata_loadRequest:(NSURLRequest *)request;

- (WKNavigation *)hinadata_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL;

- (WKNavigation *)hinadata_loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL;

- (WKNavigation *)hinadata_loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL;

@end

NS_ASSUME_NONNULL_END
