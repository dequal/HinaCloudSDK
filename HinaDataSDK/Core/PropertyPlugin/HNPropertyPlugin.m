//
// HNPropertyPlugin.m
// HinaDataSDK
//
// Created by hina on 2022/4/24.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNPropertyPlugin.h"
#import "HNPropertyPlugin+HNPrivate.h"

@implementation HNPropertyPlugin

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityDefault;
}

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    return YES;
}

@end

#pragma mark -

@implementation HNPropertyPlugin (HNPublic)

- (void)readyWithProperties:(NSDictionary<NSString *, id> *)properties {
    self.properties = properties;
    if (self.handler) {
        self.handler(properties);
    }
}

@end
