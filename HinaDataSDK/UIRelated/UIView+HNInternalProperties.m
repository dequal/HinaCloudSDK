//
// UIView+HNInternalProperties.m
// HinaDataSDK
//
// Created by hina on 2022/8/30.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HNInternalProperties.h"
#import "HNUIProperties.h"

@implementation UIView (HNInternalProperties)

- (UIViewController<HNUIViewControllerInternalProperties> *)hinadata_viewController {
    UIViewController *viewController = [HNUIProperties findNextViewControllerByResponder:self];

    // 获取当前 controller 作为 screen_name
    if (!viewController || [viewController isKindOfClass:UIAlertController.class]) {
        viewController = [HNUIProperties currentViewController];
    }
    return (UIViewController<HNUIViewControllerInternalProperties> *)viewController;
}

@end
