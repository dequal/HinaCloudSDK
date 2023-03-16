//
// HNAppClickTracker.m
// HinaDataSDK
//
// Created by hina on 2022/4/27.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAppClickTracker.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"
#import "HNAutoTrackProperty.h"
#import "HNConstants.h"
#import "HNValidator.h"
#import "HNAutoTrackUtils.h"
#import "UIView+HNAutoTrack.h"
#import "UIViewController+HNAutoTrack.h"
#import "HNModuleManager.h"
#import "HNLog.h"

@interface HNAppClickTracker ()

@property (nonatomic, strong) NSMutableSet<Class> *ignoredViewTypeList;

@end

@implementation HNAppClickTracker

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _ignoredViewTypeList = [NSMutableSet set];
    }
    return self;
}

#pragma mark - Override

- (NSString *)eventId {
    return kHNEventNameAppClick;
}

- (BOOL)shouldTrackViewController:(UIViewController *)viewController {
    if ([self isViewControllerIgnored:viewController]) {
        return NO;
    }

    return ![self isBlackListContainsViewController:viewController];
}

#pragma mark - Public Methods

- (void)autoTrackEventWithView:(UIView *)view {
    // 判断时间间隔
    if (![HNAutoTrackUtils isValidAppClickForObject:view]) {
        return;
    }

    NSMutableDictionary *properties = [HNAutoTrackUtils propertiesWithAutoTrackObject:view viewController:nil];
    if (!properties) {
        return;
    }

    // 保存当前触发时间
    view.hinadata_timeIntervalForLastAppClick = [[NSProcessInfo processInfo] systemUptime];

    [self autoTrackEventWithView:view properties:properties];
}

- (void)autoTrackEventWithScrollView:(UIScrollView *)scrollView atIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *properties = [HNAutoTrackUtils propertiesWithAutoTrackObject:(UIScrollView<HNAutoTrackViewProperty> *)scrollView didSelectedAtIndexPath:indexPath];
    if (!properties) {
        return;
    }
    NSDictionary *dic = [HNAutoTrackUtils propertiesWithAutoTrackDelegate:scrollView didSelectedAtIndexPath:indexPath];
    [properties addEntriesFromDictionary:dic];

    // 解析 Cell
    UIView *cell = [HNAutoTrackUtils cellWithScrollView:scrollView selectedAtIndexPath:indexPath];
    if (!cell) {
        return;
    }

    [self autoTrackEventWithView:cell properties:properties];
}

- (void)autoTrackEventWithGestureView:(UIView *)view {
    NSMutableDictionary *properties = [[HNAutoTrackUtils propertiesWithAutoTrackObject:view] mutableCopy];
    if (properties.count == 0) {
        return;
    }

    [self autoTrackEventWithView:view properties:properties];
}

- (void)trackEventWithView:(UIView *)view properties:(NSDictionary<NSString *,id> *)properties {
    @try {
        if (view == nil) {
            return;
        }
        NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc]init];
        [eventProperties addEntriesFromDictionary:[HNAutoTrackUtils propertiesWithAutoTrackObject:view isCodeTrack:YES]];
        if ([HNValidator isValidDictionary:properties]) {
            [eventProperties addEntriesFromDictionary:properties];
        }

        // 添加自定义属性
        [HNModuleManager.sharedInstance visualPropertiesWithView:view completionHandler:^(NSDictionary * _Nullable visualProperties) {
            if (visualProperties) {
                [eventProperties addEntriesFromDictionary:visualProperties];
            }

            [self trackPresetEventWithProperties:eventProperties];
        }];
    } @catch (NSException *exception) {
        HNLogError(@"%@: %@", self, exception);
    }
}

- (void)ignoreViewType:(Class)aClass {
    [_ignoredViewTypeList addObject:aClass];
}

- (BOOL)isViewTypeIgnored:(Class)aClass {
    for (Class obj in _ignoredViewTypeList) {
        if ([aClass isSubclassOfClass:obj]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isIgnoreEventWithView:(UIView *)view {
    return self.isIgnored || [self isViewTypeIgnored:[view class]];
}

#pragma mark – Private Methods

- (BOOL)isBlackListContainsViewController:(UIViewController *)viewController {
    NSDictionary *autoTrackBlackList = [self autoTrackViewControllerBlackList];
    NSDictionary *appClickBlackList = autoTrackBlackList[kHNEventNameAppClick];
    return [self isViewController:viewController inBlackList:appClickBlackList];
}

- (void)autoTrackEventWithView:(UIView *)view properties:(NSDictionary<NSString *, id> * _Nullable)properties {
    if (self.isIgnored) {
        return;
    }

    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
    [HNModuleManager.sharedInstance visualPropertiesWithView:view completionHandler:^(NSDictionary * _Nullable visualProperties) {
        if (visualProperties) {
            [eventProperties addEntriesFromDictionary:visualProperties];
        }

        [self trackAutoTrackEventWithProperties:eventProperties];
    }];
}

@end
