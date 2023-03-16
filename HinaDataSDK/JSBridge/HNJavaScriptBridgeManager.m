//
// HNScriptMessageHandler.m
// HinaDataSDK
//
// Created by hina on 2022/3/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNJavaScriptBridgeManager.h"
#import "HNLog.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"
#import "HNModuleManager.h"
#import "WKWebView+HNBridge.h"
#import "HNJSONUtil.h"
#import "HNSwizzle.h"
#import "HinaDataSDK+JavaScriptBridge.h"


@implementation HNJavaScriptBridgeManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNJavaScriptBridgeManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNJavaScriptBridgeManager alloc] init];
    });
    return manager;
}

#pragma mark - HNModuleProtocol

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    if (enable) {
        [self swizzleWebViewMethod];
    }
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    _configOptions = configOptions;
    self.enable = configOptions.enableJavaScriptBridge;
}

#pragma mark - HNJavaScriptBridgeModuleProtocol

- (NSString *)javaScriptSource {
    if (!self.configOptions.enableJavaScriptBridge) {
        return nil;
    }
    if (self.configOptions.serverURL) {
        return [HNJavaScriptBridgeBuilder buildJSBridgeWithServerURL:self.configOptions.serverURL];
    }

    HNLogError(@"%@ get network serverURL is failed!", self);
    return nil;
}

#pragma mark - Private

- (void)swizzleWebViewMethod {
    static dispatch_once_t onceTokenWebView;
    dispatch_once(&onceTokenWebView, ^{
        NSError *error = NULL;

        [WKWebView sa_swizzleMethod:@selector(loadRequest:)
                         withMethod:@selector(hinadata_loadRequest:)
                              error:&error];

        [WKWebView sa_swizzleMethod:@selector(loadHTMLString:baseURL:)
                         withMethod:@selector(hinadata_loadHTMLString:baseURL:)
                              error:&error];

        if (@available(iOS 9.0, *)) {
            [WKWebView sa_swizzleMethod:@selector(loadFileURL:allowingReadAccessToURL:)
                             withMethod:@selector(hinadata_loadFileURL:allowingReadAccessToURL:)
                                  error:&error];

            [WKWebView sa_swizzleMethod:@selector(loadData:MIMEType:characterEncodingName:baseURL:)
                             withMethod:@selector(hinadata_loadData:MIMEType:characterEncodingName:baseURL:)
                                  error:&error];
        }

        if (error) {
            HNLogError(@"Failed to swizzle on WKWebView. Details: %@", error);
            error = NULL;
        }
    });
}

- (void)addScriptMessageHandlerWithWebView:(WKWebView *)webView {
    NSAssert([webView isKindOfClass:[WKWebView class]], @"This injection solution only supports WKWebView! ❌");
    if (![webView isKindOfClass:[WKWebView class]]) {
        return;
    }

    @try {
        WKUserContentController *contentController = webView.configuration.userContentController;
        [contentController removeScriptMessageHandlerForName:HN_SCRIPT_MESHNGE_HANDLER_NAME];
        [contentController addScriptMessageHandler:[HNJavaScriptBridgeManager defaultManager] name:HN_SCRIPT_MESHNGE_HANDLER_NAME];

        NSString *javaScriptSource = [HNModuleManager.sharedInstance javaScriptSource];
        if (javaScriptSource.length == 0) {
            return;
        }

        NSArray<WKUserScript *> *userScripts = contentController.userScripts;
        __block BOOL isContainJavaScriptBridge = NO;
        [userScripts enumerateObjectsUsingBlock:^(WKUserScript *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if ([obj.source containsString:kHNJSBridgeServerURL] || [obj.source containsString:kHNJSBridgeVisualizedMode]) {
                isContainJavaScriptBridge = YES;
                *stop = YES;
            }
        }];

        if (!isContainJavaScriptBridge) {
            // forMainFrameOnly:标识脚本是仅应注入主框架（YES）还是注入所有框架（NO）
            WKUserScript *userScript = [[WKUserScript alloc] initWithSource:[NSString stringWithString:javaScriptSource] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
            [contentController addUserScript:userScript];

            // 通知其他模块，开启打通 H5
            if ([javaScriptSource containsString:kHNJSBridgeServerURL]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:HN_H5_BRIDGE_NOTIFICATION object:webView];
            }
        }
    } @catch (NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
}

#pragma mark - Delegate

// Invoked when a script message is received from a webpage
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if (![message.name isEqualToString:HN_SCRIPT_MESHNGE_HANDLER_NAME]) {
        return;
    }
    
    if (![message.body isKindOfClass:[NSString class]]) {
        HNLogError(@"Message body is not kind of 'NSString' from JS SDK");
        return;
    }
    
    @try {
        NSString *body = message.body;
        NSData *messageData = [body dataUsingEncoding:NSUTF8StringEncoding];
        if (!messageData) {
            HNLogError(@"Message body is invalid from JS SDK");
            return;
        }
        
        NSDictionary *messageDic = [HNJSONUtil JSONObjectWithData:messageData];
        if (![messageDic isKindOfClass:[NSDictionary class]]) {
            HNLogError(@"Message body is formatted failure from JS SDK");
            return;
        }
        
        NSString *callType = messageDic[@"callType"];
        if ([callType isEqualToString:@"app_h5_track"]) {
            // H5 发送事件
            NSDictionary *trackMessageDic = messageDic[@"data"];
            if (![trackMessageDic isKindOfClass:[NSDictionary class]]) {
                HNLogError(@"Data of message body is not kind of 'NSDictionary' from JS SDK");
                return;
            }
            
            NSString *trackMessageString = [HNJSONUtil stringWithJSONObject:trackMessageDic];
            [[HinaDataSDK sharedInstance] trackFromH5WithEvent:trackMessageString];
        } else if ([callType isEqualToString:@"visualized_track"] || [callType isEqualToString:@"app_alert"] || [callType isEqualToString:@"page_info"]) {
            /* 缓存 H5 页面信息
             visualized_track：H5 可点击元素数据，数组；
             app_alert：H5 弹框信息，提示配置错误信息；
             page_info：H5 页面信息，包括 url、title 和 lib_version
             */
            [[NSNotificationCenter defaultCenter] postNotificationName:kHNVisualizedMessageFromH5Notification object:message];
        } else if ([callType isEqualToString:@"abtest"]) {
            // 通知 HinaABTest，接收到 H5 的请求数据
            [[NSNotificationCenter defaultCenter] postNotificationName:HN_H5_MESHNGE_NOTIFICATION object:message];
        }
    } @catch (NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
}

@end

/// 打通 Bridge
NSString * const kHNJSBridgeObject = @"window.HinaData_iOS_JS_Bridge = {};";

/// 打通设置 serverURL
NSString * const kHNJSBridgeServerURL = @"window.HinaData_iOS_JS_Bridge.hinadata_app_server_url";

/// 可视化 Bridge
NSString * const kHNVisualBridgeObject = @"window.HinaData_App_Visual_Bridge = {};";

/// 标识扫码进入可视化模式
NSString * const kHNJSBridgeVisualizedMode = @"window.HinaData_App_Visual_Bridge.hinadata_visualized_mode";

/// 自定义属性 Bridge
NSString * const kHNVisualPropertyBridge = @"window.HinaData_APP_New_H5_Bridge = {};";

/// 写入自定义属性配置
NSString * const kHNJSBridgeVisualConfig = @"window.HinaData_APP_New_H5_Bridge.hinadata_get_app_visual_config";

/// js 方法调用
NSString * const kHNJSBridgeCallMethod = @"window.hinadata_app_call_js";

@implementation HNJavaScriptBridgeBuilder

#pragma mark 注入 js

/// 注入打通bridge，并设置 serverURL
/// @param serverURL 数据接收地址
+ (nullable NSString *)buildJSBridgeWithServerURL:(NSString *)serverURL {
    if (serverURL.length == 0) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@%@ = '%@';", kHNJSBridgeObject, kHNJSBridgeServerURL, serverURL];
}

/// 注入可视化 bridge，并设置扫码模式
/// @param isVisualizedMode 是否为可视化扫码模式
+ (nullable NSString *)buildVisualBridgeWithVisualizedMode:(BOOL)isVisualizedMode {
    return [NSString stringWithFormat:@"%@%@ = %@;", kHNVisualBridgeObject, kHNJSBridgeVisualizedMode, isVisualizedMode ? @"true" : @"false"];
}

/// 注入自定义属性 bridge，配置信息
/// @param originalConfig 配置信息原始 json
+ (nullable NSString *)buildVisualPropertyBridgeWithVisualConfig:(NSDictionary *)originalConfig {
    if (originalConfig.count == 0) {
        return nil;
    }
    NSMutableString *javaScriptSource = [NSMutableString stringWithString:kHNVisualPropertyBridge];
    [javaScriptSource appendString:kHNJSBridgeVisualConfig];

    // 注入完整配置信息
    NSData *callJSData = [HNJSONUtil dataWithJSONObject:originalConfig];
    // base64 编码，避免转义字符丢失的问题
    NSString *callJSJsonString = [callJSData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    [javaScriptSource appendFormat:@" = '%@';", callJSJsonString];
    return [javaScriptSource copy];
}

#pragma mark JS 方法调用
+ (nullable NSString *)buildCallJSMethodStringWithType:(HNJavaScriptCallJSType)type jsonObject:(nullable id)object {
    NSString *typeString = [self callJSTypeStringWithType:type];
    if (!typeString) {
        return nil;
    }
    NSMutableString *javaScriptSource = [NSMutableString stringWithString:kHNJSBridgeCallMethod];
    if (!object) {
        [javaScriptSource appendFormat:@"('%@')", typeString];
        return [javaScriptSource copy];
    }

    NSData *callJSData = [HNJSONUtil dataWithJSONObject:object];
    if (!callJSData) {
        return nil;
    }
    // base64 编码，避免转义字符丢失的问题
    NSString *callJSJsonString = [callJSData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    [javaScriptSource appendFormat:@"('%@', '%@')", typeString, callJSJsonString];
    return [javaScriptSource copy];
}

+ (nullable NSString *)callJSTypeStringWithType:(HNJavaScriptCallJSType)type {
    switch (type) {
        case HNJavaScriptCallJSTypeVisualized:
            return @"visualized";
        case HNJavaScriptCallJSTypeCheckJSSDK:
            return @"hinadata-check-jssdk";
        case HNJavaScriptCallJSTypeUpdateVisualConfig:
            return @"updateH5VisualConfig";
        case HNJavaScriptCallJSTypeWebVisualProperties:
            return @"getJSVisualProperties";
        default:
            return nil;
    }
}

@end
