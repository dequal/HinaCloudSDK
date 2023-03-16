//
// HNAppStartTracker.m
// HinaDataSDK
//
// Created by hina on 2022/4/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAppStartTracker.h"
#import "HNStoreManager.h"
#import "HNConstants+Private.h"
#import "HinaDataSDK+Private.h"

// App 启动标记
static NSString * const kHNHasLaunchedOnce = @"HasLaunchedOnce";
// App 首次启动
static NSString * const kHNEventPropertyAppFirstStart = @"H_is_first_time";
// App 是否从后台恢复
static NSString * const kHNEventPropertyResumeFromBackground = @"H_resume_from_background";

@interface HNAppStartTracker ()

/// 是否为热启动
@property (nonatomic, assign, getter=isRelaunch) BOOL relaunch;

@end

@implementation HNAppStartTracker

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _relaunch = NO;
    }
    return self;
}

#pragma mark - Override

- (NSString *)eventId {
    return self.isPassively ? kHNEventNameAppStartPassively : kHNEventNameAppStart;
}

#pragma mark - Public Methods

- (void)autoTrackEventWithProperties:(NSDictionary *)properties {
    if (!self.isIgnored) {
        NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
        if (self.isPassively) {
            eventProperties[kHNEventPropertyAppFirstStart] = @([self isFirstAppStart]);
            eventProperties[kHNEventPropertyResumeFromBackground] = @(NO);
        } else {
            eventProperties[kHNEventPropertyAppFirstStart] = self.isRelaunch ? @(NO) : @([self isFirstAppStart]);
            eventProperties[kHNEventPropertyResumeFromBackground] = self.isRelaunch ? @(YES) : @(NO);
        }
        //添加 deepLink 相关渠道信息，可能不存在
        [eventProperties addEntriesFromDictionary:properties];

        [self trackAutoTrackEventWithProperties:eventProperties];

        // 上报启动事件（包括冷启动和热启动）
        if (!self.passively) {
            [HinaDataSDK.sharedInstance flush];
        }
    }

    // 更新首次标记
    [self updateFirstAppStart];

    // 触发过启动事件，下次为热启动
    self.relaunch = YES;
}

#pragma mark – Private Methods

- (BOOL)isFirstAppStart {
    return ![[HNStoreManager sharedInstance] boolForKey:kHNHasLaunchedOnce];
}

- (void)updateFirstAppStart {
    if ([self isFirstAppStart]) {
        [[HNStoreManager sharedInstance] setBool:YES forKey:kHNHasLaunchedOnce];
    }
}

@end
