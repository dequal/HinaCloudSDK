//
// HNEventObjectFactory.m
// HinaDataSDK
//
// Created by hina on 2022/4/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNEventObjectFactory.h"
#import "HNProfileEventObject.h"
#import "HNTrackEventObject.h"
#import "HNItemEventObject.h"
#import "HNConstants+Private.h"

@implementation HNEventObjectFactory

+ (HNBaseEventObject *)eventObjectWithH5Event:(NSDictionary *)event {
    NSString *type = event[kHNEventType];
    if ([type isEqualToString:kHNEventTypeTrack]) {
        return [[HNCustomEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kHNEventTypeSignup]) {
        return [[HNSignUpEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kHNEventTypeBind]) {
        return [[HNBindEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kHNEventTypeUnbind]) {
        return [[HNUnbindEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kHNProfileSet]) {
        return [[HNProfileEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kHNProfileSetOnce]) {
        return [[HNProfileEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kHNProfileUnset]) {
        return [[HNProfileEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kHNProfileDelete]) {
        return [[HNProfileEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kHNProfileAppend]) {
        return [[HNProfileAppendEventObject alloc] initWithH5Event:event];
    }
    if ([type isEqualToString:kHNProfileIncrement]) {
        return [[HNProfileIncrementEventObject alloc] initWithH5Event:event];
    }
    // H5 打通暂不支持 item 事件
    return [[HNBaseEventObject alloc] initWithH5Event:event];
}

@end
