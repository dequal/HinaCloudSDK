//
// HNVisualizedDebugLogTracker.h
// HinaDataSDK
//
// Created by hina on 2022/3/3.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNEventIdentifier.h"
NS_ASSUME_NONNULL_BEGIN

/// 诊断日志
@interface HNVisualizedDebugLogTracker : NSObject

/// 所有日志信息
@property (atomic, strong, readonly) NSMutableArray<NSMutableDictionary *> *debugLogInfos;

/// 元素点击事件信息
- (void)addTrackEventWithView:(UIView *)view withConfig:(NSDictionary *)config;

@end

NS_ASSUME_NONNULL_END
