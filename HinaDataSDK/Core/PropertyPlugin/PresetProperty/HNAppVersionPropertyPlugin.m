//
// HNAppVersionPropertyPlugin.m
// HinaDataSDK
//
// Created by hina on 2022/1/12.
// Copyright © 2022 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAppVersionPropertyPlugin.h"

/// 应用版本
static NSString * const kHNPropertyPluginAppVersion = @"H_app_version";

@interface HNAppVersionPropertyPlugin()
@property (nonatomic, copy) NSString *appVersion;
@end

@implementation HNAppVersionPropertyPlugin

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    return filter.type & HNEventTypeDefault;
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityLow;
}

- (void)prepare {
    self.appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSDictionary<NSString *,id> *)properties {
    if (!self.appVersion) {
        return nil;
    }
    return @{kHNPropertyPluginAppVersion: self.appVersion};
}

@end
