//
// UIView+HNElementPath.h
// HinaDataSDK
//
// Created by hina on 2022/3/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "HNWebElementView.h"
#import "HNAutoTrackProperty.h"
#import "HNVisualizedViewPathProperty.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - UIView
@interface UIView (HNVisualizedViewPath)<HNVisualizedViewPathProperty, HNVisualizedExtensionProperty>

/// 判断 ReactNative 元素是否可点击
- (BOOL)hinadata_clickableForRNView;

/// 判断一个 view 是否显示
- (BOOL)hinadata_isVisible;

@end

@interface WKWebView (HNVisualizedViewPath)<HNVisualizedViewPathProperty>

@end

@interface UIWindow (HNVisualizedViewPath)<HNVisualizedViewPathProperty>
@end

/// 其他平台的构造可视化页面元素
@interface HNVisualizedElementView (HNElementPath)<HNVisualizedViewPathProperty>
@end

/// App 内嵌 H5 页面元素信息
@interface HNWebElementView (HNElementPath)<HNVisualizedViewPathProperty>

@end

#pragma mark - UIControl
@interface UISwitch (HNVisualizedViewPath)<HNVisualizedViewPathProperty>
@end

@interface UIStepper (HNVisualizedViewPath)<HNVisualizedViewPathProperty>
@end

@interface UISlider (HNVisualizedViewPath)<HNVisualizedViewPathProperty>
@end

@interface UIPageControl (HNVisualizedViewPath)<HNVisualizedViewPathProperty>
@end

#pragma mark - TableView & Cell
@interface UITableView (HNVisualizedViewPath)<HNVisualizedViewPathProperty>
@end

@interface UICollectionView (HNVisualizedViewPath)<HNVisualizedViewPathProperty>
@end

@interface UITableViewCell (HNVisualizedViewPath)
@end

@interface UICollectionViewCell (HNVisualizedViewPath)
@end

NS_ASSUME_NONNULL_END
