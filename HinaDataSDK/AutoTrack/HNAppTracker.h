//
// HNAppTracker.h
// HinaDataSDK
//
// Created by hina on 2022/5/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import "HNConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNAppTracker : NSObject

/// 是否忽略事件
@property (nonatomic, assign, getter=isIgnored) BOOL ignored;
/// 是否被动启动
@property (nonatomic, assign, getter=isPassively) BOOL passively;
/// 用户设置的不被 AutoTrack 的 Controllers
@property (nonatomic, strong) NSMutableSet<NSString *> *ignoredViewControllers;

/// 获取 tracker 对应的事件 ID
- (NSString *)eventId;

/// 触发全埋点事件
/// @param properties 事件属性
- (void)trackAutoTrackEventWithProperties:(nullable NSDictionary *)properties;

/// 触发手动采集预置事件
/// @param properties 事件属性
- (void)trackPresetEventWithProperties:(nullable NSDictionary *)properties;

/// 根据 UIViewController 判断，是否采集事件
/// @param viewController 事件采集时的控制器
- (BOOL)shouldTrackViewController:(UIViewController *)viewController;

/// 在 AutoTrack 时，用户可以设置哪些 controllers 不被 AutoTrack
/// @param controllers controller ‘字符串’数组
- (void)ignoreAutoTrackViewControllers:(NSArray<NSString *> *)controllers;

/// 判断某个 ViewController 是否被忽略
/// @param viewController UIViewController
- (BOOL)isViewControllerIgnored:(UIViewController *)viewController;

/// ViewController 的黑名单
- (NSDictionary *)autoTrackViewControllerBlackList;

/// 判断某个 ViewController 是否处于黑名单
/// @param viewController UIViewController
/// @param blackList 黑名单
- (BOOL)isViewController:(UIViewController *)viewController inBlackList:(NSDictionary *)blackList;

@end

NS_ASSUME_NONNULL_END
