//
// HNVisualizedEventCheck.h
// HinaDataSDK
//
// Created by hina on 2022/3/22.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNVisualPropertiesConfigSources.h"

NS_ASSUME_NONNULL_BEGIN

/// 可视化全埋点埋点校验
@interface HNVisualizedEventCheck : NSObject
- (instancetype)initWithConfigSources:(HNVisualPropertiesConfigSources *)configSources;

/// 筛选事件结果
@property (nonatomic, strong, readonly) NSArray<NSDictionary *> *eventCheckResult;

/// 清除调试事件
- (void)cleanEventCheckResult;
@end

NS_ASSUME_NONNULL_END
