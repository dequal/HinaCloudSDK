//
// UIViewController+HNAutoTrack.m
// HinaDataSDK
//
// Created by hina on 2022/10/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "UIViewController+HNAutoTrack.h"
#import "HinaDataSDK.h"
#import "HNCommonUtility.h"
#import "HNLog.h"
#import "UIView+HNAutoTrack.h"
#import "HNAutoTrackManager.h"
#import "HNWeakPropertyContainer.h"
#import <objc/runtime.h>

static void *const kHNPreviousViewController = (void *)&kHNPreviousViewController;

@implementation UIViewController (AutoTrack)

- (BOOL)hinadata_isIgnored {
    return ![[HNAutoTrackManager defaultManager].appClickTracker shouldTrackViewController:self];
}

- (void)sa_autotrack_viewDidAppear:(BOOL)animated {
    // 防止 tabbar 切换，可能漏采 H_AppViewScreen 全埋点
    if ([self isKindOfClass:UINavigationController.class]) {
        UINavigationController *nav = (UINavigationController *)self;
        nav.hinadata_previousViewController = nil;
    }

    HNAppViewScreenTracker *appViewScreenTracker = HNAutoTrackManager.defaultManager.appViewScreenTracker;

    // parentViewController 判断，防止开启子页面采集时候的侧滑多采集父页面 H_AppViewScreen 事件
    if (self.navigationController && self.parentViewController == self.navigationController) {
        // 全埋点中，忽略由于侧滑部分返回原页面，重复触发 H_AppViewScreen 事件
        if (self.navigationController.hinadata_previousViewController == self) {
            return [self sa_autotrack_viewDidAppear:animated];
        }
    }

    
    if (HNAutoTrackManager.defaultManager.configOptions.enableAutoTrackChildViewScreen ||
        !self.parentViewController ||
        [self.parentViewController isKindOfClass:[UITabBarController class]] ||
        [self.parentViewController isKindOfClass:[UINavigationController class]] ||
        [self.parentViewController isKindOfClass:[UIPageViewController class]] ||
        [self.parentViewController isKindOfClass:[UISplitViewController class]]) {
        [appViewScreenTracker autoTrackEventWithViewController:self];
    }

    // 标记 previousViewController
    if (self.navigationController && self.parentViewController == self.navigationController) {
        self.navigationController.hinadata_previousViewController = self;
    }

    [self sa_autotrack_viewDidAppear:animated];
}

@end

@implementation UINavigationController (AutoTrack)

- (void)setHinadata_previousViewController:(UIViewController *)hinadata_previousViewController {
    HNWeakPropertyContainer *container = [HNWeakPropertyContainer containerWithWeakProperty:hinadata_previousViewController];
    objc_setAssociatedObject(self, kHNPreviousViewController, container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIViewController *)hinadata_previousViewController {
    HNWeakPropertyContainer *container = objc_getAssociatedObject(self, kHNPreviousViewController);
    return container.weakProperty;
}

@end
