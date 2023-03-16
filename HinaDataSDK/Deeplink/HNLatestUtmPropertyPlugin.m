//
// HNLatestUtmPropertyPlugin.m
// HinaDataSDK
//
// Created by  hina on 2022/4/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNLatestUtmPropertyPlugin.h"
#import "HNModuleManager.h"
#import "HNDeepLinkConstants.h"
#import "HNConstants+Private.h"

@implementation HNLatestUtmPropertyPlugin

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    // 手动调用接口采集 H_AppDeeplinkLaunch 事件, 不需要添加 H_latest_utm_xxx 属性
    if ([self.filter.event isEqualToString:kHNAppDeepLinkLaunchEvent] && [self.filter.lib.method isEqualToString:kHNLibMethodCode]) {
        return NO;
    }
    return filter.type & HNEventTypeDefault;
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    return HNModuleManager.sharedInstance.latestUtmProperties;
}

@end
