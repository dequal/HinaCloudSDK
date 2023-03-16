//
// HNAppStartTracker.h
// HinaDataSDK
//
// Created by hina on 2022/4/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNAppTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNAppStartTracker : HNAppTracker

/// 触发全埋点启动事件
/// @param properties 事件属性
- (void)autoTrackEventWithProperties:(nullable NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
