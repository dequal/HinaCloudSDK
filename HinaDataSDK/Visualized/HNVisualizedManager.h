//
// HNVisualizedManager.h
// HinaDataSDK
//
// Created by hina on 2022/12/25.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HNVisualPropertiesTracker.h"
#import "HNVisualizedEventCheck.h"
#import "HNVisualizedConnection.h"

typedef NS_ENUM(NSInteger, HinaDataVisualizedType) {
    HinaDataVisualizedTypeUnknown,  // 未知或不允许
    HinaDataVisualizedTypeHeatMap, // 点击图
    HinaDataVisualizedTypeAutoTrack  //可视化全埋点
};

NS_ASSUME_NONNULL_BEGIN

@interface HNVisualizedManager : NSObject<HNModuleProtocol, HNOpenURLProtocol, HNVisualizedModuleProtocol, HNJavaScriptBridgeModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) HNConfigOptions *configOptions;

/// 自定义属性采集
@property (nonatomic, strong, readonly) HNVisualPropertiesTracker *visualPropertiesTracker;

/// 当前连接类型
@property (nonatomic, assign, readonly) HinaDataVisualizedType visualizedType;

/// 可视化全埋点配置资源
@property (nonatomic, strong, readonly) HNVisualPropertiesConfigSources *configSources;

/// 埋点校验
@property (nonatomic, strong, readonly) HNVisualizedEventCheck *eventCheck;

@property (nonatomic, strong, readonly) HNVisualizedConnection *visualizedConnection;


/// 是否开启埋点校验
- (void)enableEventCheck:(BOOL)enable;

/// 指定页面开启可视化
/// @param controllers  需要开启可视化 ViewController 的类名
- (void)addVisualizeWithViewControllers:(NSArray<NSString *> *)controllers;

/// 判断某个页面是否开启可视化
/// @param viewController 当前页面 viewController
- (BOOL)isVisualizeWithViewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
