//
// UIViewController+HNElementPath.h
// HinaDataSDK
//
// Created by hina on 2022/3/15.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HNVisualizedViewPathProperty.h"

NS_ASSUME_NONNULL_BEGIN


@interface UIViewController (HNElementPath)<HNVisualizedViewPathProperty>

- (void)hinadata_visualize_viewDidAppear:(BOOL)animated;

@end

@interface UITabBarController (HNElementPath)<HNVisualizedViewPathProperty>

@end

@interface UINavigationController (HNElementPath)<HNVisualizedViewPathProperty>

@end

@interface UIPageViewController (HNElementPath)<HNVisualizedViewPathProperty>

@end

NS_ASSUME_NONNULL_END
