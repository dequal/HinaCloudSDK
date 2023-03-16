//
// HNUIProperties.m
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNUIProperties.h"
#import "UIView+HNItemPath.h"
#import "UIView+HNSimilarPath.h"
#import "UIAlertController+HNSimilarPath.h"
#import "HNCommonUtility.h"
#import "HNConstants+Private.h"
#import "UIView+HNElementID.h"
#import "UIView+HNElementType.h"
#import "UIView+HNElementContent.h"
#import "UIView+HNElementPosition.h"
#import "UIView+HNInternalProperties.h"
#import "UIView+HinaData.h"
#import "UIViewController+HNInternalProperties.h"
#import "HNValidator.h"
#import "HNModuleManager.h"
#import "UIView+HinaData.h"
#import "HNLog.h"

@implementation HNUIProperties

+ (NSInteger)indexWithResponder:(UIResponder *)responder {
    NSString *classString = NSStringFromClass(responder.class);
    NSInteger index = -1;
    NSArray<UIResponder *> *brothersResponder = [self siblingElementsOfResponder:responder];

    for (UIResponder *res in brothersResponder) {
        if ([classString isEqualToString:NSStringFromClass(res.class)]) {
            index ++;
        }
        if (res == responder) {
            break;
        }
    }

    /* 序号说明
     -1：nextResponder 不是父视图或同类元素，比如 controller.view，涉及路径不带序号
     >=0：元素序号
     */
    return index;
}

/// 寻找所有兄弟元素
+ (NSArray <UIResponder *> *)siblingElementsOfResponder:(UIResponder *)responder {
    if ([responder isKindOfClass:UIView.class]) {
        UIResponder *next = [responder nextResponder];
        if ([next isKindOfClass:UIView.class]) {
            NSArray<UIView *> *subViews = [(UIView *)next subviews];
            if ([next isKindOfClass:UISegmentedControl.class]) {
                // UISegmentedControl 点击之后，subviews 顺序会变化，需要根据坐标排序才能得到准确序号
                NSArray<UIView *> *brothers = [subViews sortedArrayUsingComparator:^NSComparisonResult (UIView *obj1, UIView *obj2) {
                    if (obj1.frame.origin.x > obj2.frame.origin.x) {
                        return NSOrderedDescending;
                    } else {
                        return NSOrderedAscending;
                    }
                }];
                return brothers;
            }
            return subViews;
        }
    } else if ([responder isKindOfClass:UIViewController.class]) {
        return [(UIViewController *)responder parentViewController].childViewControllers;
    }
    return nil;
}

+ (BOOL)isIgnoredItemPathWithView:(UIView *)view {
    NSString *className = NSStringFromClass(view.class);
    /* 类名黑名单，忽略元素相对路径
     为了兼容不同系统、不同状态下的路径匹配，忽略区分元素的路径
     */
    NSArray <NSString *>*ignoredItemClassNames = @[@"UITableViewWrapperView", @"UISegment", @"_UISearchBarFieldEditor", @"UIFieldEditor"];
    return [ignoredItemClassNames containsObject:className];
}

+ (NSString *)elementPathForView:(UIView *)view atViewController:(UIViewController *)viewController {
    NSMutableArray *viewPathArray = [NSMutableArray array];
    BOOL isContainSimilarPath = NO;

    do {
        if (isContainSimilarPath) { // 防止 cell 等列表嵌套，被拼上多个 [-]
            if (view.hinadata_itemPath) {
                [viewPathArray addObject:view.hinadata_itemPath];
            }
        } else {
            NSString *currentSimilarPath = view.hinadata_similarPath;
            if (currentSimilarPath) {
                [viewPathArray addObject:currentSimilarPath];
                if ([currentSimilarPath containsString:@"[-]"]) {
                    isContainSimilarPath = YES;
                }
            }
        }
    } while ((view = (id)view.nextResponder) && [view isKindOfClass:UIView.class]);

    if ([view isKindOfClass:UIAlertController.class]) {
        UIAlertController<HNUIViewPathProperties> *viewController = (UIAlertController<HNUIViewPathProperties> *)view;
        [viewPathArray addObject:viewController.hinadata_similarPath];
    }

    NSString *viewPath = [[[viewPathArray reverseObjectEnumerator] allObjects] componentsJoinedByString:@"/"];

    return viewPath;
}

+ (UIViewController *)findNextViewControllerByResponder:(UIResponder *)responder {
    UIResponder *next = responder;
    do {
        if (![next isKindOfClass:UIViewController.class]) {
            continue;
        }
        UIViewController *vc = (UIViewController *)next;
        if ([vc isKindOfClass:UINavigationController.class]) {
            return [self findNextViewControllerByResponder:[(UINavigationController *)vc topViewController]];
        } else if ([vc isKindOfClass:UITabBarController.class]) {
            return [self findNextViewControllerByResponder:[(UITabBarController *)vc selectedViewController]];
        }

        UIViewController *parentVC = vc.parentViewController;
        if (!parentVC) {
            break;
        }
        if ([parentVC isKindOfClass:UINavigationController.class] ||
            [parentVC isKindOfClass:UITabBarController.class] ||
            [parentVC isKindOfClass:UIPageViewController.class] ||
            [parentVC isKindOfClass:UISplitViewController.class]) {
            break;
        }
    } while ((next = next.nextResponder));
    return [next isKindOfClass:UIViewController.class] ? (UIViewController *)next : nil;
}

+ (UIViewController *)currentViewController {
    __block UIViewController *currentViewController = nil;
    void (^ block)(void) = ^{
        UIViewController *rootViewController = UIApplication.sharedApplication.keyWindow.rootViewController;
        currentViewController = [HNUIProperties findCurrentViewControllerFromRootViewController:rootViewController isRoot:YES];
    };

    [HNCommonUtility performBlockOnMainThread:block];
    return currentViewController;
}

+ (UIViewController *)findCurrentViewControllerFromRootViewController:(UIViewController *)viewController isRoot:(BOOL)isRoot {
    if ([self canFindPresentedViewController:viewController.presentedViewController]) {
         return [self findCurrentViewControllerFromRootViewController:viewController.presentedViewController isRoot:NO];
     }

    if ([viewController isKindOfClass:[UITabBarController class]]) {
        return [self findCurrentViewControllerFromRootViewController:[(UITabBarController *)viewController selectedViewController] isRoot:NO];
    }

    if ([viewController isKindOfClass:[UINavigationController class]]) {
        // 根视图为 UINavigationController
        UIViewController *topViewController = [(UINavigationController *)viewController topViewController];
        return [self findCurrentViewControllerFromRootViewController:topViewController isRoot:NO];
    }

    if (viewController.childViewControllers.count > 0) {
        if (viewController.childViewControllers.count == 1 && isRoot) {
            return [self findCurrentViewControllerFromRootViewController:viewController.childViewControllers.firstObject isRoot:NO];
        } else {
            __block UIViewController *currentViewController = viewController;
            //从最上层遍历（逆序），查找正在显示的 UITabBarController 或 UINavigationController 类型的
            // 是否包含 UINavigationController 或 UITabBarController 类全屏显示的 controller
            [viewController.childViewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
                // 判断 obj.view 是否加载，如果尚未加载，调用 obj.view 会触发 viewDidLoad，可能影响客户业务
                if (obj.isViewLoaded) {
                    CGPoint point = [obj.view convertPoint:CGPointZero toView:nil];
                    CGSize windowSize = obj.view.window.bounds.size;
                   // 正在全屏显示
                    BOOL isFullScreenShow = !obj.view.hidden && obj.view.alpha > 0.01 && CGPointEqualToPoint(point, CGPointZero) && CGSizeEqualToSize(obj.view.bounds.size, windowSize);
                   // 判断类型
                    BOOL isStopFindController = [obj isKindOfClass:UINavigationController.class] || [obj isKindOfClass:UITabBarController.class];
                    if (isFullScreenShow && isStopFindController) {
                        currentViewController = [self findCurrentViewControllerFromRootViewController:obj isRoot:NO];
                        *stop = YES;
                    }
                }
            }];
            return currentViewController;
        }
    } else if ([viewController respondsToSelector:NSSelectorFromString(@"contentViewController")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        UIViewController *tempViewController = [viewController performSelector:NSSelectorFromString(@"contentViewController")];
#pragma clang diagnostic pop
        if (tempViewController) {
            return [self findCurrentViewControllerFromRootViewController:tempViewController isRoot:NO];
        }
    }
    return viewController;
}

+ (BOOL)canFindPresentedViewController:(UIViewController *)viewController {
    if (!viewController) {
        return NO;
    }
    if ([viewController isKindOfClass:UIAlertController.class]) {
        return NO;
    }
    if ([@"_UIContextMenuActionsOnlyViewController" isEqualToString:NSStringFromClass(viewController.class)]) {
        return NO;
    }
    return YES;
}

+ (NSDictionary *)propertiesWithView:(UIView *)view viewController:(UIViewController *)viewController {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    
    viewController = viewController ? : view.hinadata_viewController;
    NSDictionary *dic = [self propertiesWithViewController:viewController];
    [properties addEntriesFromDictionary:dic];

    properties[kHNEventPropertyElementId] = view.hinadata_elementId;
    properties[kHNEventPropertyElementType] = view.hinadata_elementType;
    properties[kHNEventPropertyElementContent] = view.hinadata_elementContent;
    properties[kHNEventPropertyElementPosition] = view.hinadata_elementPosition;
    [properties addEntriesFromDictionary:view.hinaDataViewProperties];

    // viewPath
    NSDictionary *viewPathProperties = [[HNModuleManager sharedInstance] propertiesWithView:view];
    if (viewPathProperties) {
        [properties addEntriesFromDictionary:viewPathProperties];
    }
    return properties;
}

+ (NSDictionary *)propertiesWithScrollView:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath {
    UIView *cell = [self cellWithScrollView:scrollView andIndexPath:indexPath];
    return [self propertiesWithScrollView:scrollView cell:cell];
}

+ (NSDictionary *)propertiesWithScrollView:(UIScrollView *)scrollView cell:(UIView *)cell {
    if (!cell) {
        return nil;
    }
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    UIViewController *viewController = scrollView.hinadata_viewController;
    NSDictionary *dic = [self propertiesWithViewController:viewController];
    [properties addEntriesFromDictionary:dic];

    properties[kHNEventPropertyElementId] = scrollView.hinadata_elementId;
    properties[kHNEventPropertyElementType] = scrollView.hinadata_elementType;
    properties[kHNEventPropertyElementContent] = cell.hinadata_elementContent;
    properties[kHNEventPropertyElementPosition] = cell.hinadata_elementPosition;

    //View Properties
    NSDictionary *viewProperties = scrollView.hinaDataViewProperties;
    if (viewProperties.count > 0) {
        [properties addEntriesFromDictionary:viewProperties];
    }

    // viewPath
    NSDictionary *viewPathProperties = [[HNModuleManager sharedInstance] propertiesWithView:cell];
    if (viewPathProperties) {
        [properties addEntriesFromDictionary:viewPathProperties];
    }
    return [properties copy];
}

+ (NSDictionary *)propertiesWithViewController:(UIViewController *)viewController {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[kHNEventPropertyScreenName] = viewController.hinadata_screenName;
    properties[kHNEventPropertyTitle] = viewController.hinadata_title;

    SEL getTrackProperties = NSSelectorFromString(@"getTrackProperties");
    if ([viewController respondsToSelector:getTrackProperties]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        NSDictionary *trackProperties = [viewController performSelector:getTrackProperties];
#pragma clang diagnostic pop
        if ([HNValidator isValidDictionary:trackProperties]) {
            [properties addEntriesFromDictionary:trackProperties];
        }
    }
    return [properties copy];
}

+ (UIView *)cellWithScrollView:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath {
    UIView *cell = nil;
    if ([scrollView isKindOfClass:UITableView.class]) {
        UITableView *tableView = (UITableView *)scrollView;
        cell = [tableView cellForRowAtIndexPath:indexPath];
        if (!cell) {
            [tableView layoutIfNeeded];
            cell = [tableView cellForRowAtIndexPath:indexPath];
        }
    } else if ([scrollView isKindOfClass:UICollectionView.class]) {
        UICollectionView *collectionView = (UICollectionView *)scrollView;
        cell = [collectionView cellForItemAtIndexPath:indexPath];
        if (!cell) {
            [collectionView layoutIfNeeded];
            cell = [collectionView cellForItemAtIndexPath:indexPath];
        }
    }
    return cell;
}

+ (NSDictionary *)propertiesWithAutoTrackDelegate:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *properties = nil;
    @try {
        if ([scrollView isKindOfClass:UITableView.class]) {
            UITableView *tableView = (UITableView *)scrollView;

            if ([tableView.hinaDataDelegate respondsToSelector:@selector(hinaData_tableView:autoTrackPropertiesAtIndexPath:)]) {
                properties = [tableView.hinaDataDelegate hinaData_tableView:tableView autoTrackPropertiesAtIndexPath:indexPath];
            }
        } else if ([scrollView isKindOfClass:UICollectionView.class]) {
            UICollectionView *collectionView = (UICollectionView *)scrollView;
            if ([collectionView.hinaDataDelegate respondsToSelector:@selector(hinaData_collectionView:autoTrackPropertiesAtIndexPath:)]) {
                properties = [collectionView.hinaDataDelegate hinaData_collectionView:collectionView autoTrackPropertiesAtIndexPath:indexPath];
            }
        }
    } @catch (NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
    NSAssert(!properties || [properties isKindOfClass:[NSDictionary class]], @"You must return a dictionary object ❌");
    return properties;
}

@end
