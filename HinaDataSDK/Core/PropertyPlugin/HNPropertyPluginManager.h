//
// HNPropertyPluginManager.h
// HinaDataSDK
//
// Created by hina on 2022/9/6.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

extern const NSUInteger kHNPropertyPluginPrioritySuper;

#pragma mark -

@interface HNPropertyPluginManager : NSObject

+ (instancetype)sharedInstance;

/// 注册属性插件
///
/// 该方法需要在触发事件的队列中执行，保证属性查询时与事件正确对应
///
/// @param plugin 属性插件对象
- (void)registerPropertyPlugin:(HNPropertyPlugin *)plugin;

/// 注销属性插件
///
/// @param cla 插件类型
- (void)unregisterPropertyPluginWithPluginClass:(Class)cla;

/// 注册自定义属性插件
///
/// 该方法需要在触发事件的队列中执行，保证属性查询时与事件正确对应，采集后失效
///
/// @param plugin 属性插件对象
- (void)registerCustomPropertyPlugin:(HNPropertyPlugin *)plugin;

/// 通过属性插件类获取属性插件当前采集的属性
/// @param classes 属性插件类
/// @return 属性字典
- (NSMutableDictionary<NSString *, id> *)currentPropertiesForPluginClasses:(NSArray<Class> *)classes;

/// 通过事件名和事件类型获取属性
///
/// 需要在触发事件的队列中调用
///
/// @param filter 事件名
- (NSMutableDictionary<NSString *, id> *)propertiesWithFilter:(id<HNPropertyPluginEventFilter>)filter;

/// 通过类获取属性插件
/// 某些属性插件，需要获取后进行一些特定操作，比如公共属性，需要在 serialQueue 执行
///
/// @param cla 插件类
/// @return 插件对象
- (nullable HNPropertyPlugin *)pluginsWithPluginClass:(Class)cla;

@end

NS_ASSUME_NONNULL_END
