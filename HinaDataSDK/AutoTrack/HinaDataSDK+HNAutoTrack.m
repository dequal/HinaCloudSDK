//
// HinaDataSDK+HNAutoTrack.m
// HinaDataSDK
//
// Created by hina on 2022/4/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HinaDataSDK+HNAutoTrack.h"
#import "HinaDataSDK+Private.h"
#import "HNAutoTrackUtils.h"
#import "HNAutoTrackManager.h"
#import "HNModuleManager.h"
#import "HNWeakPropertyContainer.h"
#include <objc/runtime.h>
#import "HNUIProperties.h"

@implementation UIImage (HinaData)

- (NSString *)hinaDataImageName {
    return objc_getAssociatedObject(self, @"hinaDataImageName");
}

- (void)setHinaDataImageName:(NSString *)hinaDataImageName {
    objc_setAssociatedObject(self, @"hinaDataImageName", hinaDataImageName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

#pragma mark -

@implementation HinaDataSDK (HNAutoTrack)

- (UIViewController *)currentViewController {
    return [HNUIProperties currentViewController];
}

- (BOOL)isAutoTrackEnabled {
    return [HNAutoTrackManager.defaultManager isAutoTrackEnabled];
}

#pragma mark - Ignore

- (BOOL)isAutoTrackEventTypeIgnored:(HinaDataAutoTrackEventType)eventType {
    return [HNAutoTrackManager.defaultManager isAutoTrackEventTypeIgnored:eventType];
}

- (void)ignoreViewType:(Class)aClass {
    [HNAutoTrackManager.defaultManager.appClickTracker ignoreViewType:aClass];
}

- (BOOL)isViewTypeIgnored:(Class)aClass {
    return [HNAutoTrackManager.defaultManager.appClickTracker isViewTypeIgnored:aClass];
}

- (void)ignoreAutoTrackViewControllers:(NSArray<NSString *> *)controllers {
    [HNAutoTrackManager.defaultManager.appClickTracker ignoreAutoTrackViewControllers:controllers];
    [HNAutoTrackManager.defaultManager.appViewScreenTracker ignoreAutoTrackViewControllers:controllers];
}

- (BOOL)isViewControllerIgnored:(UIViewController *)viewController {
    BOOL isIgnoreAppClick = [HNAutoTrackManager.defaultManager.appClickTracker isViewControllerIgnored:viewController];
    BOOL isIgnoreAppViewScreen = [HNAutoTrackManager.defaultManager.appViewScreenTracker isViewControllerIgnored:viewController];

    return isIgnoreAppClick || isIgnoreAppViewScreen;
}

#pragma mark - Track

- (void)trackViewAppClick:(UIView *)view {
    [self trackViewAppClick:view withProperties:nil];
}

- (void)trackViewAppClick:(UIView *)view withProperties:(NSDictionary *)p {
    [HNAutoTrackManager.defaultManager.appClickTracker trackEventWithView:view properties:p];
}

- (void)trackViewScreen:(UIViewController *)controller {
    [self trackViewScreen:controller properties:nil];
}

- (void)trackViewScreen:(UIViewController *)controller properties:(nullable NSDictionary<NSString *, id> *)properties {
    [HNAutoTrackManager.defaultManager.appViewScreenTracker trackEventWithViewController:controller properties:properties];
}

- (void)trackViewScreen:(NSString *)url withProperties:(NSDictionary *)properties {
    [HNAutoTrackManager.defaultManager.appViewScreenTracker trackEventWithURL:url properties:properties];
}

#pragma mark - Deprecated

- (void)enableAutoTrack:(HinaDataAutoTrackEventType)eventType {
    if (self.configOptions.autoTrackEventType != eventType) {
        self.configOptions.autoTrackEventType = eventType;

        HNAutoTrackManager.defaultManager.enable = YES;
        
        [HNAutoTrackManager.defaultManager updateAutoTrackEventType];
    }
}

@end
