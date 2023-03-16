//
// HNReferrerTitlePropertyPlugin.m
// HinaDataSDK
//
// Created by  hina on 2022/4/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNReferrerTitlePropertyPlugin.h"
#import "HNReferrerManager.h"
#import "HNConstants+Private.h"
#import "HNPropertyPlugin+HNPrivate.h"

@implementation HNReferrerTitlePropertyPlugin

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    // 不支持 H5 打通事件
    if ([filter hybridH5]) {
        return NO;
    }
    return filter.type & HNEventTypeDefault;
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    NSString *referrerTitle = [HNReferrerManager.sharedInstance referrerTitle];
    if (!referrerTitle) {
        return nil;
    }
    return @{kHNEeventPropertyReferrerTitle: referrerTitle};
}

@end
