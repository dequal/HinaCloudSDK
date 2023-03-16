//
// HNFirstDayPropertyPlugin.h
// HinaDataSDK
//
// Created by  hina on 2022/5/5.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

/// 是否首日属性采集插件
@interface HNFirstDayPropertyPlugin : HNPropertyPlugin

- (instancetype)initWithQueue:(dispatch_queue_t)queue;

- (BOOL)isFirstDay;

@end

NS_ASSUME_NONNULL_END
