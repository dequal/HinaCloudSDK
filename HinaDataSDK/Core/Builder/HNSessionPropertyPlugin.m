//
// HNSessionPropertyPlugin.m
// HinaDataSDK
//
// Created by  hina on 2022/5/5.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNSessionPropertyPlugin.h"
#import "HNPropertyPluginManager.h"
#import "HNSessionProperty.h"

@interface HNSessionPropertyPlugin()

@property (nonatomic, weak) HNSessionProperty *sessionProperty;

@end

@implementation HNSessionPropertyPlugin

- (instancetype)initWithSessionProperty:(HNSessionProperty *)sessionProperty {
    NSAssert(sessionProperty, @"You must initialize sessionProperty");
    if (!sessionProperty) {
        return nil;
    }

    self = [super init];
    if (self) {
        _sessionProperty = sessionProperty;
    }
    return self;
}

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    return filter.type & HNEventTypeDefault;
}

- (HNPropertyPluginPriority)priority {
    return kHNPropertyPluginPrioritySuper;
}

- (NSDictionary<NSString *,id> *)properties {
    if (!self.filter) {
        return nil;
    }
    NSDictionary *properties = [self.sessionProperty sessionPropertiesWithEventTime:@(self.filter.time)];
    return properties;
}

@end
