//
// HNAppClickTracker.h
// HinaDataSDK
//
// Created by hina on 2022/4/27.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import "HNAppTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNAppClickTracker : HNAppTracker

/// 触发 UIApplication 全埋点点击事件
/// @param view UIView
- (void)autoTrackEventWithView:(UIView *)view;

/// 触发 Cell 全埋点点击事件
/// @param scrollView cell 所在的视图
/// @param indexPath cell 位置
- (void)autoTrackEventWithScrollView:(UIScrollView *)scrollView atIndexPath:(NSIndexPath *)indexPath;

/// 触发 Gesture 全埋点点击事件
/// @param view UIView
- (void)autoTrackEventWithGestureView:(UIView *)view;

/// 通过代码触发 UIView 的 H_AppClick 事件
/// @param view UIView
/// @param properties 自定义属性
- (void)trackEventWithView:(UIView *)view properties:(NSDictionary<NSString *, id> * _Nullable)properties;

/// 忽略某一类型的 View
/// @param aClass View 对应的 Class
- (void)ignoreViewType:(Class)aClass;

/// 判断某个 View 类型是否被忽略
/// @param aClass Class View 对应的 Class
- (BOOL)isViewTypeIgnored:(Class)aClass;

/// 是否忽略视图的点击事件
/// @param view UIView
- (BOOL)isIgnoreEventWithView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
