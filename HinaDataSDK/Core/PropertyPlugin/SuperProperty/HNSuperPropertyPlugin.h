//
// HNSuperPropertyPlugin.h
// HinaDataSDK
//
// Created by  hina on 2022/4/22.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

/// 静态公共属性采集插件
@interface HNSuperPropertyPlugin : HNPropertyPlugin

/// 注册公共属性
- (void)registerSuperProperties:(NSDictionary *)propertyDict;

/// 移除某个公共属性
///
/// @param property 属性的 key
- (void)unregisterSuperProperty:(NSString *)property;

/// 清空公共属性
- (void)clearSuperProperties;

/// 注销仅大小写不同的 SuperProperties
/// @param propertyDict 需要校验的属性
- (void)unregisterSameLetterSuperProperties:(NSDictionary *)propertyDict;

@end

NS_ASSUME_NONNULL_END
