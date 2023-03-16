//
// HNModulePropertyPlugin.m
// HinaDataSDK
//
// Created by  hina on 2022/5/5.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNModulePropertyPlugin.h"
#import "HNModuleManager.h"
#import "HNPropertyPlugin+HNPrivate.h"

@implementation HNModulePropertyPlugin

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    // 不支持 H5 打通事件
    if ([filter hybridH5]) {
        return NO;
    }
    return filter.type & HNEventTypeDefault;
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityHigh;
}

- (NSDictionary<NSString *,id> *)properties {
    return HNModuleManager.sharedInstance.properties;
}

@end
