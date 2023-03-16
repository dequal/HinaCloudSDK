//
// HNEventDurationPropertyPlugin.m
// HinaDataSDK
//
// Created by  hina on 2022/4/24.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNEventDurationPropertyPlugin.h"
#import "HNConstants+Private.h"
#import "HNPropertyPlugin+HNPrivate.h"
#import "HNBaseEventObject.h"

@interface HNEventDurationPropertyPlugin()
@property (nonatomic, weak) HNTrackTimer *trackTimer;
@end

@implementation HNEventDurationPropertyPlugin

- (instancetype)initWithTrackTimer:(HNTrackTimer *)trackTimer {
    NSAssert(trackTimer, @"You must initialize trackTimer");
    if (!trackTimer) {
        return nil;
    }
    self = [super init];
    if (self) {
        self.trackTimer = trackTimer;
    }
    return self;
}

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
    if (![self.filter isKindOfClass:HNBaseEventObject.class]) {
        return nil;
    }

    HNBaseEventObject *eventObject = (HNBaseEventObject *)self.filter;
    NSNumber *eventDuration = [self.trackTimer eventDurationFromEventId:eventObject.eventId currentSysUpTime:eventObject.currentSystemUpTime];
    if (!eventDuration) {
        return nil;
    }
    return @{@"event_duration": eventDuration};
}

@end
