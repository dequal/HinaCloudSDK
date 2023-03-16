//
// HNDynamicSuperPropertyPlugin.h
// HinaDataSDK
//
// Created by  hina on 2022/4/24.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSDictionary<NSString *, id> *_Nullable(^HNDynamicSuperPropertyBlock)(void);

/// 动态公共属性采集插件
@interface HNDynamicSuperPropertyPlugin : HNPropertyPlugin

/// 动态公共属性采集插件实例
+ (HNDynamicSuperPropertyPlugin *)sharedDynamicSuperPropertyPlugin;

/// 注册动态公共属性
///
/// @param dynamicSuperPropertiesBlock 动态公共属性的回调
- (void)registerDynamicSuperPropertiesBlock:(HNDynamicSuperPropertyBlock)dynamicSuperPropertiesBlock;

/// 准备采集动态公共属性
///
/// 需要在队列外执行
- (void)buildDynamicSuperProperties;

@end

NS_ASSUME_NONNULL_END
