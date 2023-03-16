//
// WKWebView+HNBridge.m
// HinaDataSDK
//
// Created by hina on 2022/3/21.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "WKWebView+HNBridge.h"
#import "HNJavaScriptBridgeManager.h"

@implementation WKWebView (HNBridge)

- (WKNavigation *)hinadata_loadRequest:(NSURLRequest *)request {
    [[HNJavaScriptBridgeManager defaultManager] addScriptMessageHandlerWithWebView:self];
    
    return [self hinadata_loadRequest:request];
}

- (WKNavigation *)hinadata_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    [[HNJavaScriptBridgeManager defaultManager] addScriptMessageHandlerWithWebView:self];
    
    return [self hinadata_loadHTMLString:string baseURL:baseURL];
}

- (WKNavigation *)hinadata_loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL {
    [[HNJavaScriptBridgeManager defaultManager] addScriptMessageHandlerWithWebView:self];
    
    return [self hinadata_loadFileURL:URL allowingReadAccessToURL:readAccessURL];
}

- (WKNavigation *)hinadata_loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL {
    [[HNJavaScriptBridgeManager defaultManager] addScriptMessageHandlerWithWebView:self];
    
    return [self hinadata_loadData:data MIMEType:MIMEType characterEncodingName:characterEncodingName baseURL:baseURL];
}

@end
