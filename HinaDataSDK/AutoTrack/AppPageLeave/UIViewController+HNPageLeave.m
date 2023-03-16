//
// UIViewController+PageView.m
// HinaDataSDK
//
// Created by hina on 2022/7/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIViewController+HNPageLeave.h"
#import "HNAutoTrackManager.h"


@implementation UIViewController (HNPageLeave)

- (void)hinadata_pageLeave_viewDidAppear:(BOOL)animated {
    HNAppPageLeaveTracker *tracker = [HNAutoTrackManager defaultManager].appPageLeaveTracker;
    [tracker trackPageEnter:self];
    [self hinadata_pageLeave_viewDidAppear:animated];
}

- (void)hinadata_pageLeave_viewDidDisappear:(BOOL)animated {
    HNAppPageLeaveTracker *tracker = [HNAutoTrackManager defaultManager].appPageLeaveTracker;
    [tracker trackPageLeave:self];
    [self hinadata_pageLeave_viewDidDisappear:animated];
}



@end
