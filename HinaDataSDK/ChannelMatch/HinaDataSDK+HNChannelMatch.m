//
// HinaDataSDK+HNChannelMatch.m
// HinaDataSDK
//
// Created by hina on 2022/7/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HinaDataSDK+HNChannelMatch.h"
#import "HinaDataSDK+Private.h"
#import "HNTrackEventObject.h"
#import "HNModuleManager.h"
#import "HNChannelMatchManager.h"

// 激活事件
static NSString * const kHNEventNameAppInstall = @"H_AppInstall";

@interface HinaDataSDK ()

@end

@implementation HinaDataSDK (HNChannelMatch)

- (void)trackChannelEvent:(NSString *)event {
    [self trackChannelEvent:event properties:nil];
}

- (void)trackChannelEvent:(NSString *)event properties:(nullable NSDictionary *)propertyDict {
    HNCustomEventObject *object = [[HNCustomEventObject alloc] initWithEventId:event];

    // 入队列前，执行动态公共属性采集 block
    [self buildDynamicSuperProperties];
    dispatch_async(self.serialQueue, ^{
        [HNChannelMatchManager.defaultManager trackChannelWithEventObject:object properties:propertyDict];
    });
}

- (void)trackAppInstall {
    [self trackAppInstallWithProperties:nil];
}

- (void)trackAppInstallWithProperties:(NSDictionary *)properties {
    [self trackAppInstallWithProperties:properties disableCallback:NO];
}

- (void)trackAppInstallWithProperties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback {
    // 入队列前，执行动态公共属性采集 block
    [self buildDynamicSuperProperties];

    dispatch_async(self.serialQueue, ^{
        if (![HNChannelMatchManager.defaultManager isTrackedAppInstallWithDisableCallback:disableCallback]) {
            [HNChannelMatchManager.defaultManager setTrackedAppInstallWithDisableCallback:disableCallback];
            [HNChannelMatchManager.defaultManager trackAppInstall:kHNEventNameAppInstall properties:properties disableCallback:disableCallback];
            [self flush];
        }
    });
}

- (void)trackInstallation:(NSString *)event {
    [self trackInstallation:event withProperties:nil disableCallback:NO];
}

- (void)trackInstallation:(NSString *)event withProperties:(NSDictionary *)propertyDict {
    [self trackInstallation:event withProperties:propertyDict disableCallback:NO];
}

- (void)trackInstallation:(NSString *)event withProperties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback {

    // 入队列前，执行动态公共属性采集 block
    [self buildDynamicSuperProperties];
    dispatch_async(self.serialQueue, ^{
        if (![HNChannelMatchManager.defaultManager isTrackedAppInstallWithDisableCallback:disableCallback]) {
            [HNChannelMatchManager.defaultManager setTrackedAppInstallWithDisableCallback:disableCallback];
            [HNChannelMatchManager.defaultManager trackAppInstall:event properties:properties disableCallback:disableCallback];
            [self flush];
        }
    });
}

@end
