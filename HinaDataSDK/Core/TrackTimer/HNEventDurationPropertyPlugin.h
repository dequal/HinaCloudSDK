//
// HNEventDurationPropertyPlugin.h
// HinaDataSDK
//
// Created by  hina on 2022/4/24.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNPropertyPlugin.h"
#import "HNTrackTimer.h"

NS_ASSUME_NONNULL_BEGIN

/// 事件时长属性插件
@interface HNEventDurationPropertyPlugin :HNPropertyPlugin


/// 事件时长属性插件初始化
/// @param trackTimer 事件计时器
- (instancetype)initWithTrackTimer:(HNTrackTimer *)trackTimer NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
