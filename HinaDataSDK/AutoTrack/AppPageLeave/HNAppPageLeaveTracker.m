//
// HNAppPageLeaveTracker.m
// HinaDataSDK
//
// Created by hina on 2022/7/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAppPageLeaveTracker.h"
#import "HNAutoTrackUtils.h"
#import "HinaDataSDK+HNAutoTrack.h"
#import "HNConstants+Private.h"
#import "HNConstants+Private.h"
#import "HNAppLifecycle.h"
#import "HinaDataSDK+Private.h"
#import "HNAutoTrackManager.h"
#import "HNUIProperties.h"

@implementation HNPageLeaveObject

@end

@interface HNAppPageLeaveTracker ()

@property (nonatomic, copy) NSString *referrerURL;
@property (nonatomic, assign) HNAppLifecycleState appState;

@end

@implementation HNAppPageLeaveTracker

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateWillChange:) name:kHNAppLifecycleStateWillChangeNotification object:nil];
    }
    return self;
}

- (NSString *)eventId {
    return kHNEventNameAppPageLeave;
}

- (void)trackEvents {
    [self.pageLeaveObjects enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, HNPageLeaveObject * _Nonnull obj, BOOL * _Nonnull stop) {
        if (!obj.viewController) {
            return;
        }
        NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
        NSTimeInterval startTimestamp = obj.timestamp;
        NSMutableDictionary *tempProperties = [[NSMutableDictionary alloc] initWithDictionary:[self propertiesWithViewController:obj.viewController]];
        NSTimeInterval duration = (currentTimestamp - startTimestamp) < 24 * 60 * 60 ? (currentTimestamp - startTimestamp) : 0;
        tempProperties[kHNEventDurationProperty] = @([[NSString stringWithFormat:@"%.3f", duration] floatValue]);
        if (obj.referrerURL) {
            tempProperties[kHNEventPropertyScreenReferrerUrl] = obj.referrerURL;
        }
        [self trackWithProperties:[tempProperties copy]];
    }];
}

- (void)trackPageEnter:(UIViewController *)viewController {
    if (![self shouldTrackViewController:viewController]) {
        return;
    }
    NSString *address = [NSString stringWithFormat:@"%p", viewController];
    if (self.pageLeaveObjects[address]) {
        HNPageLeaveObject *object = self.pageLeaveObjects[address];
        if (![object isKindOfClass:[HNPageLeaveObject class]]) {
            return;
        }
        object.timestamp = [[NSDate date] timeIntervalSince1970];
        return;
    }
    HNPageLeaveObject *object = [[HNPageLeaveObject alloc] init];
    object.timestamp = [[NSDate date] timeIntervalSince1970];
    object.viewController = viewController;
    NSString *currentURL;
    if ([viewController conformsToProtocol:@protocol(HNScreenAutoTracker)] && [viewController respondsToSelector:@selector(getScreenUrl)]) {
        UIViewController<HNScreenAutoTracker> *screenAutoTrackerController = (UIViewController<HNScreenAutoTracker> *)viewController;
        currentURL = [screenAutoTrackerController getScreenUrl];
    }
    currentURL = [currentURL isKindOfClass:NSString.class] ? currentURL : NSStringFromClass(viewController.class);
    object.referrerURL = [self referrerURLWithURL:currentURL eventProperties:[HNUIProperties propertiesWithViewController:(UIViewController<HNAutoTrackViewControllerProperty> *)viewController]];
    self.pageLeaveObjects[address] = object;
}

- (void)trackPageLeave:(UIViewController *)viewController {
    if (![self shouldTrackViewController:viewController]) {
        return;
    }
    NSString *address = [NSString stringWithFormat:@"%p", viewController];
    HNPageLeaveObject *object = self.pageLeaveObjects[address];
    if (!object) {
        return;
    }
    NSTimeInterval currentTimestamp = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval startTimestamp = object.timestamp;
    NSMutableDictionary *tempProperties = [self propertiesWithViewController:(UIViewController<HNAutoTrackViewControllerProperty> *)(object.viewController)];
    NSTimeInterval duration = (currentTimestamp - startTimestamp) < 24 * 60 * 60 ? (currentTimestamp - startTimestamp) : 0;
    tempProperties[kHNEventDurationProperty] = @([[NSString stringWithFormat:@"%.3f", duration] floatValue]);
    if (object.referrerURL) {
        tempProperties[kHNEventPropertyScreenReferrerUrl] = object.referrerURL;
    }
    [self.pageLeaveObjects removeObjectForKey:address];
    if (self.appState == HNAppLifecycleStateEnd || self.appState == HNAppLifecycleStateStartPassively) {
        return;
    }
    [self trackWithProperties:tempProperties];
}

- (void)trackWithProperties:(NSDictionary *)properties {
    HNPresetEventObject *object = [[HNPresetEventObject alloc] initWithEventId:kHNEventNameAppPageLeave];

    [HinaDataSDK.sharedInstance trackEventObject:object properties:properties];
}

- (void)appLifecycleStateWillChange:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    HNAppLifecycleState newState = [userInfo[kHNAppLifecycleNewStateKey] integerValue];
    self.appState = newState;
    // 冷（热）启动
    if (newState == HNAppLifecycleStateStart) {
        [self.pageLeaveObjects enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, HNPageLeaveObject * _Nonnull obj, BOOL * _Nonnull stop) {
            obj.timestamp = [[NSDate date] timeIntervalSince1970];
        }];
        return;
    }
    // 退出
    if (newState == HNAppLifecycleStateEnd) {
        [self trackEvents];
    }
}

- (NSMutableDictionary *)propertiesWithViewController:(UIViewController<HNAutoTrackViewControllerProperty> *)viewController {
    NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc] init];
    NSDictionary *autoTrackProperties = [HNUIProperties propertiesWithViewController:viewController];
    [eventProperties addEntriesFromDictionary:autoTrackProperties];
    if (eventProperties[kHNEventPropertyScreenUrl]) {
        return eventProperties;
    }
    NSString *currentURL;
    if ([viewController conformsToProtocol:@protocol(HNScreenAutoTracker)] && [viewController respondsToSelector:@selector(getScreenUrl)]) {
        UIViewController<HNScreenAutoTracker> *screenAutoTrackerController = (UIViewController<HNScreenAutoTracker> *)viewController;
        currentURL = [screenAutoTrackerController getScreenUrl];
    }
    currentURL = [currentURL isKindOfClass:NSString.class] ? currentURL : NSStringFromClass(viewController.class);
    eventProperties[kHNEventPropertyScreenUrl] = currentURL;
    return eventProperties;
}

- (NSString *)referrerURLWithURL:(NSString *)currentURL eventProperties:(NSDictionary *)eventProperties {
    NSString *referrerURL = self.referrerURL;
    NSMutableDictionary *newProperties = [NSMutableDictionary dictionaryWithDictionary:eventProperties];

    // 客户自定义属性中包含 H_url 时，以客户自定义内容为准
    if (!newProperties[kHNEventPropertyScreenUrl]) {
        newProperties[kHNEventPropertyScreenUrl] = currentURL;
    }
    // 客户自定义属性中包含 H_referrer 时，以客户自定义内容为准
    if (referrerURL && !newProperties[kHNEventPropertyScreenReferrerUrl]) {
        newProperties[kHNEventPropertyScreenReferrerUrl] = referrerURL;
    }
    // H_referrer 内容以最终页面浏览事件中的 H_url 为准
    self.referrerURL = newProperties[kHNEventPropertyScreenUrl];

    return newProperties[kHNEventPropertyScreenReferrerUrl];
}

- (BOOL)shouldTrackViewController:(UIViewController *)viewController {
    NSDictionary *autoTrackBlackList = [self autoTrackViewControllerBlackList];
    NSDictionary *appViewScreenBlackList = autoTrackBlackList[kHNEventNameAppViewScreen];
    if ([self isViewController:viewController inBlackList:appViewScreenBlackList]) {
        return NO;
    }
    if ([HNAutoTrackManager.defaultManager.configOptions.ignoredPageLeaveClasses containsObject:[viewController class]]) {
        return NO;
    }
    if (HNAutoTrackManager.defaultManager.configOptions.enableTrackChildPageLeave ||
        !viewController.parentViewController ||
        [viewController.parentViewController isKindOfClass:[UITabBarController class]] ||
        [viewController.parentViewController isKindOfClass:[UINavigationController class]] ||
        [viewController.parentViewController isKindOfClass:[UIPageViewController class]] ||
        [viewController.parentViewController isKindOfClass:[UISplitViewController class]]) {
        return YES;
    }
    return NO;
}

- (NSMutableDictionary<NSString *,HNPageLeaveObject *> *)pageLeaveObjects {
    if (!_pageLeaveObjects) {
        _pageLeaveObjects = [[NSMutableDictionary alloc] init];
    }
    return _pageLeaveObjects;
}

@end
