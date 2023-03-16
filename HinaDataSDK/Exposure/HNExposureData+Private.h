//
// HNExposureData+Private.h
// HinaDataSDK
//
// Created by hina on 2022/8/12.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNExposureData.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNExposureData (Private)

@property (nonatomic, copy) NSString *exposureIdentifier;
@property (nonatomic, copy) NSString *event;
@property (nonatomic, copy) HNExposureConfig *config;
@property (nonatomic, copy) NSDictionary *properties;

@end

NS_ASSUME_NONNULL_END
