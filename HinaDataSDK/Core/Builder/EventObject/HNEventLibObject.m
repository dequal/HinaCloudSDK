//
// HNEventLibObject.m
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNEventLibObject.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"
#import "HNValidator.h"

/// SDK 类型
NSString * const kHNEventPresetPropertyLib = @"H_lib";
/// SDK 方法
NSString * const kHNEventPresetPropertyLibMethod = @"H_lib_method";
/// SDK 版本
NSString * const kHNEventPresetPropertyLibVersion = @"H_lib_version";
/// 埋点详情
NSString * const kHNEventPresetPropertyLibDetail = @"H_lib_detail";
/// 应用版本
NSString * const kHNEventPresetPropertyAppVersion = @"H_app_version";

@implementation HNEventLibObject

- (instancetype)init {
    self = [super init];
    if (self) {
#if TARGET_OS_IOS
        _lib = @"iOS";
#elif TARGET_OS_OSX
        _lib = @"macOS";
#endif
        _method = kHNLibMethodCode;
        _version = [HinaDataSDK libVersion];
        _appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        _detail = nil;
    }
    return self;
}

- (instancetype)initWithH5Lib:(NSDictionary *)lib {
    self = [super init];
    if (self) {
        _lib = lib[kHNEventPresetPropertyLib];
        _method = lib[kHNEventPresetPropertyLibMethod];
        _version = lib[kHNEventPresetPropertyLibVersion];

        // H5 打通事件，H_app_version 使用 App 的
        _appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
        _detail = nil;
    }
    return self;
}

- (void)setMethod:(NSString *)method {
    if (![HNValidator isValidString:method]) {
        return;
    }
    _method = method;
}

#pragma mark - public
- (NSMutableDictionary *)jsonObject {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[kHNEventPresetPropertyLib] = self.lib;
    properties[kHNEventPresetPropertyLibVersion] = self.version;
    properties[kHNEventPresetPropertyAppVersion] = self.appVersion;
    properties[kHNEventPresetPropertyLibMethod] = self.method;
    properties[kHNEventPresetPropertyLibDetail] = self.detail;
    return properties;
}

@end
