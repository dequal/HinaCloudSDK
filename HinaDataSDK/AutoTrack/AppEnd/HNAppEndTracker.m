//
// HNAppEndTracker.m
// HinaDataSDK
//
// Created by hina on 2022/4/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAppEndTracker.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"

@interface HNAppEndTracker ()

@property (nonatomic, copy) NSString *timerEventID;

@end

@implementation HNAppEndTracker

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _timerEventID = kHNEventNameAppEnd;
    }
    return self;
}

#pragma mark - Override

- (NSString *)eventId {
    return self.timerEventID ?: kHNEventNameAppEnd;
}

#pragma mark - Public Methods

- (void)autoTrackEvent {
    if (self.isIgnored) {
        return;
    }

    [self trackAutoTrackEventWithProperties:nil];
}

- (void)trackTimerStartAppEnd {
    self.timerEventID = [HinaDataSDK.sdkInstance trackTimerStart:kHNEventNameAppEnd];
}

@end
