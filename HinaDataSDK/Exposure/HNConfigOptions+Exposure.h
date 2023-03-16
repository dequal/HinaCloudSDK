//
// HNConfigOptions+Exposure.h
// HinaDataSDK
//
// Created by hina on 2022/8/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//


#import <Foundation/Foundation.h>
#import "HNConfigOptions.h"
#import "HNExposureConfig.h"
#import "HNExposureData.h"
#import "HinaDataSDK+Exposure.h"
#import "UIView+ExposureIdentifier.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNConfigOptions (Exposure)

/// global exposure config settings, default value with areaRate = 0, stayDuration = 0, repeated = YES
@property (nonatomic, copy) HNExposureConfig *exposureConfig;

@end

NS_ASSUME_NONNULL_END
