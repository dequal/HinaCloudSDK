//
// UIViewController+HNElementPath.m
// HinaDataSDK
//
// Created by hina on 2022/3/15.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIViewController+HNElementPath.h"
#import "HNVisualizedUtils.h"
#import "UIView+HNVisualizedViewPath.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"
#import "HNVisualizedObjectSerializerManager.h"
#import "HNVisualizedManager.h"
#import "HNAutoTrackManager.h"
#import "HNUIProperties.h"

@implementation UIViewController (HNElementPath)

- (NSArray *)hinadata_subElements {
    UIViewController *presentedViewController = self.presentedViewController;
    if (presentedViewController) {
        return @[presentedViewController];
    }

    if (self.childViewControllers.count == 0 || [self isKindOfClass:UIAlertController.class]) {
        if (!self.isViewLoaded) {
            return nil;
        }

        UIView *currentView = self.view;
        if (currentView && currentView.hinadata_isVisible) {
            return @[currentView];
        } else {
            return nil;
        }
    }

    CGSize fullScreenSize = UIScreen.mainScreen.bounds.size;
    NSMutableArray *subElements = [NSMutableArray array];
    //逆序遍历，从而确保从最上层开始查找，直到全屏 view 停止
    [self.view.subviews enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 跳过不可见元素
        if (![obj hinadata_isVisible]) {
            return;
        }

        // 通过 viewController.view 添加的子视图，优先获取 viewController 自身
        if ([obj.nextResponder isKindOfClass:UIViewController.class]) {
            [subElements addObject:obj.nextResponder];
        } else {
            [subElements addObject:obj];
        }

        CGRect rect = [obj convertRect:obj.bounds toView:nil];
        // 是否全屏
        BOOL isFullScreenShow = CGPointEqualToPoint(rect.origin, CGPointZero) && CGSizeEqualToSize(rect.size, fullScreenSize);
        // 正在全屏显示
        if (isFullScreenShow) {
            *stop = YES;
        }
    }];
    // 逆序翻转，保证和显示优先级一致
    return [[subElements reverseObjectEnumerator] allObjects];
}

- (void)hinadata_visualize_viewDidAppear:(BOOL)animated {
    [self hinadata_visualize_viewDidAppear:animated];

    if ([HNVisualizedManager defaultManager].configOptions.enableAutoTrackChildViewScreen ||
        !self.parentViewController ||
        [self.parentViewController isKindOfClass:[UITabBarController class]] ||
        [self.parentViewController isKindOfClass:[UINavigationController class]] ||
        [self.parentViewController isKindOfClass:[UIPageViewController class]] ||
        [self.parentViewController isKindOfClass:[UISplitViewController class]]) {
        [self hinadata_readyEnterViewController];
    }

    // 跳转进入 RN 自定义页面，需更新节点的页面名称
    if ([HNVisualizedUtils isRNCustomViewController:self]) {
        [HNVisualizedManager.defaultManager.visualPropertiesTracker enterRNViewController:self];
    }
}

- (void)hinadata_readyEnterViewController {
    if (![[HNAutoTrackManager defaultManager].appViewScreenTracker shouldTrackViewController:self]) {
        return;
    }
    // 保存最后一次页面浏览所在的 controller，用于可视化全埋点定义页面浏览
    [[HNVisualizedObjectSerializerManager sharedInstance] enterViewController:self];
}

@end

@implementation UITabBarController (HNElementPath)
- (NSArray *)hinadata_subElements {
    NSMutableArray *subElements = [NSMutableArray array];
    if (self.presentedViewController) {
        [subElements addObject:self.presentedViewController];
        return subElements;
    }

    /* 兼容场景
     可能存在元素，直接添加在 UITabBarController.view 上（即 UILayoutContainerView）
     UITabBarController 页面层级大致如下
     - UITabBarController
        - UILayoutContainerView
            - UITransitionView
            - UITabBar
     */
    NSArray<UIView *> *subViews = self.view.subviews;
    for (UIView *view in subViews) {
        if ([view isKindOfClass:UITabBar.class]) {
            // UITabBar 元素
            if (self.isViewLoaded && self.tabBar.hinadata_isVisible) {
                [subElements addObject:self.tabBar];
            }
        } else if ([NSStringFromClass(view.class) isEqualToString:@"UITransitionView"]) {
            if (self.selectedViewController) {
                [subElements addObject:self.selectedViewController];
            }
        } else if (view.hinadata_isVisible) {
            [subElements addObject:view];
        }
    }

    return subElements;
}
@end


@implementation UINavigationController (HNElementPath)
- (NSArray *)hinadata_subElements {
    NSMutableArray *subElements = [NSMutableArray array];
    if (self.presentedViewController) {
        [subElements addObject:self.presentedViewController];
        return subElements;
    }
    /* 兼容场景
     可能存在元素，直接添加在 UINavigationController.view 上（即 UILayoutContainerView）
     UINavigationController 页面层级大致如下
     - UINavigationController
        - UILayoutContainerView
            - UINavigationTransitionView
            - UINavigationBar
     */
    NSArray<UIView *> *subViews = self.view.subviews;
    for (UIView *view in subViews) {
        if ([view isKindOfClass:UINavigationBar.class]) {
            // UINavigationBar 元素
            if (self.isViewLoaded && self.navigationBar.hinadata_isVisible) {
                [subElements addObject:self.navigationBar];
            }
        } else if ([NSStringFromClass(view.class) isEqualToString:@"UINavigationTransitionView"]) {
            if (self.topViewController) {
                [subElements addObject:self.topViewController];
            }
        } else if (view.hinadata_isVisible) {
            [subElements addObject:view];
        }
    }
    return subElements;
}
@end

@implementation UIPageViewController (HNElementPath)

- (NSArray *)hinadata_subElements {
    NSMutableArray *subElements = [NSMutableArray array];
    if (self.presentedViewController) {
        [subElements addObject:self.presentedViewController];
        return subElements;
    }

    /* 兼容场景
     可能存在元素，直接添加在 UIPageViewController.view 上（即 _UIPageViewControllerContentView）
     UIPageViewController 页面层级大致如下
     - UIPageViewController
        - _UIPageViewControllerContentView
            - _UIQueuingScrollView
            - Others
     */
    for (UIView *view in self.view.subviews) {
        if ([NSStringFromClass(view.class) isEqualToString:@"_UIQueuingScrollView"]) {
            if (self.viewControllers.count > 0) {
                [subElements addObjectsFromArray:self.viewControllers];
            }
        } else if (view.hinadata_isVisible) {
            [subElements addObject:view];
        }
    }
    return subElements;
}

@end

