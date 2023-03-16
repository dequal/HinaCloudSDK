//
// HNAppPageLeaveTracker.h
// HinaDataSDK
//
// Created by hina on 2022/7/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//


#import "HNAppTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNPageLeaveObject : NSObject

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, copy) NSString *referrerURL;

@end

@interface HNAppPageLeaveTracker : HNAppTracker

@property (nonatomic, strong) NSMutableDictionary<NSString *, HNPageLeaveObject *> *pageLeaveObjects;

- (void)trackEvents;
- (void)trackPageEnter:(UIViewController *)viewController;
- (void)trackPageLeave:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
