//
// HNAppTracker.m
// HinaDataSDK
//
// Created by hina on 2022/5/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAppTracker.h"
#import "HNTrackEventObject.h"
#import "HinaDataSDK+Private.h"
#import "HNLog.h"
#import "HNConstants+Private.h"
#import "HNJSONUtil.h"
#import "HNValidator.h"

@implementation HNAppTracker

#pragma mark - Life Cycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _ignored = NO;
        _passively = NO;
        _ignoredViewControllers = [NSMutableSet set];
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)eventId {
    return nil;
}

- (void)trackAutoTrackEventWithProperties:(NSDictionary *)properties {
    HNAutoTrackEventObject *object = [[HNAutoTrackEventObject alloc] initWithEventId:[self eventId]];

    [HinaDataSDK.sharedInstance trackEventObject:object properties:properties];
}

- (void)trackPresetEventWithProperties:(NSDictionary *)properties {
    HNPresetEventObject *object  = [[HNPresetEventObject alloc] initWithEventId:[self eventId]];

    [HinaDataSDK.sharedInstance trackEventObject:object properties:properties];
}

- (BOOL)shouldTrackViewController:(UIViewController *)viewController {
    return YES;
}

- (void)ignoreAutoTrackViewControllers:(NSArray<NSString *> *)controllers {
    if (controllers == nil || controllers.count == 0) {
        return;
    }
    [self.ignoredViewControllers addObjectsFromArray:controllers];
}

- (BOOL)isViewControllerIgnored:(UIViewController *)viewController {
    if (viewController == nil) {
        return NO;
    }

    NSString *screenName = NSStringFromClass([viewController class]);
    return [self.ignoredViewControllers containsObject:screenName];
}

- (NSDictionary *)autoTrackViewControllerBlackList {
    static dispatch_once_t onceToken;
    static NSDictionary *allClasses = nil;
    dispatch_once(&onceToken, ^{
        NSBundle *hinaBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[HinaDataSDK class]] pathForResource:@"HinaDataSDK" ofType:@"bundle"]];
        //文件路径
        NSString *jsonPath = [hinaBundle pathForResource:@"sa_autotrack_viewcontroller_blacklist.json" ofType:nil];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        allClasses = [HNJSONUtil JSONObjectWithData:jsonData];
    });
    return allClasses;
}

- (BOOL)isViewController:(UIViewController *)viewController inBlackList:(NSDictionary *)blackList {
    if (!viewController || ![HNValidator isValidDictionary:blackList]) {
        return NO;
    }

    for (NSString *publicClass in blackList[@"public"]) {
        if ([viewController isKindOfClass:NSClassFromString(publicClass)]) {
            return YES;
        }
    }
    return [(NSArray *)blackList[@"private"] containsObject:NSStringFromClass(viewController.class)];
}

@end
