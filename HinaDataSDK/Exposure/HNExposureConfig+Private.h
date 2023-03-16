//
// HNExposureConfig+Private.h
// HinaDataSDK
//
// Created by hina on 2022/8/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNExposureConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNExposureConfig (Private)

/// visable area rate, 0 ~ 1, default value is 0
@property (nonatomic, assign, readonly) CGFloat areaRate;

/// stay duration, default value is 0, unit is second
@property (nonatomic, assign, readonly) NSTimeInterval stayDuration;

/// allow repeated exposure or not, default value is YES
@property (nonatomic, assign, readonly) BOOL repeated;

@end

NS_ASSUME_NONNULL_END
