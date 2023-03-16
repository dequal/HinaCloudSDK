//
// HNAppEndTracker.h
// HinaDataSDK
//
// Created by hina on 2022/4/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNAppTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNAppEndTracker : HNAppTracker

/// 触发全埋点退出事件
- (void)autoTrackEvent;

/// 开始退出事件计时
- (void)trackTimerStartAppEnd;

@end

NS_ASSUME_NONNULL_END
