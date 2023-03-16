//
// HNFlutterPluginBridge.m
// HinaDataSDK
//
// Created by  hina on 2022/7/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNFlutterPluginBridge.h"
#import "HNVisualizedObjectSerializerManager.h"
#import "HNVisualizedManager.h"
#import "HNJSONUtil.h"
#import "HNValidator.h"
#import "HNLog.h"


/** 可视化全埋点状态改变，包括连接状态和自定义属性配置

    userInfo 传递参数

    可视化全埋点连接状态改变: {context：connectionStatus}

    自定义属性配置更新: {context：propertiesConfig}
 */
static NSNotificationName const kHNVisualizedStatusChangedNotification = @"HinaDataVisualizedStatusChangedNotification";

@interface HNFlutterPluginBridge()

@property (nonatomic, copy) NSString *visualPropertiesConfig;

@end

@implementation HNFlutterPluginBridge

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HNFlutterPluginBridge *bridge = nil;
    dispatch_once(&onceToken, ^{
        bridge = [[HNFlutterPluginBridge alloc] init];
    });
    return bridge;
}

- (BOOL)isVisualConnectioned {
    return [HNVisualizedManager.defaultManager.visualizedConnection isVisualizedConnecting];
}

// 修改可视化全埋点连接状态
- (void)changeVisualConnectionStatus:(BOOL)isConnectioned {

    [[NSNotificationCenter defaultCenter] postNotificationName:kHNVisualizedStatusChangedNotification object:nil userInfo:@{@"context": @"connectionStatus"}];
}

// 修改自定义属性配置
- (void)changeVisualPropertiesConfig:(NSDictionary *)propertiesConfig {
    if (![HNValidator isValidDictionary:propertiesConfig]) {
        return;
    }

    // 注入完整配置信息
    NSData *callJSData = [HNJSONUtil dataWithJSONObject:propertiesConfig];
    // base64 编码，避免转义字符丢失的问题
    NSString *base64JsonString = [callJSData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    self.visualPropertiesConfig = base64JsonString;

    [[NSNotificationCenter defaultCenter] postNotificationName:kHNVisualizedStatusChangedNotification object:nil userInfo:@{@"context": @"propertiesConfig"}];

}

// 更新 Flutter 页面元素信息
- (void)updateFlutterElementInfo:(NSString *)jsonString {
    if (!jsonString) {
        return;
    }
    NSMutableDictionary *messageDic = [HNJSONUtil JSONObjectWithString:jsonString options:NSJSONReadingMutableContainers];
    if (![messageDic isKindOfClass:[NSDictionary class]]) {
        HNLogError(@"Message body is formatted failure from Flutter");
        return;
    }
    [[HNVisualizedObjectSerializerManager sharedInstance] saveVisualizedMessage:messageDic];
}

@end
