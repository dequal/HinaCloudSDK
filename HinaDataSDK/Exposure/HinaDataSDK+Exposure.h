//
// HinaDataSDK+Exposure.h
// HinaDataSDK
//
// Created by hina on 2022/8/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HinaDataSDK.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HinaDataSDK (Exposure)

- (void)addExposureView:(UIView *)view withData:(HNExposureData *)data;
- (void)removeExposureView:(UIView *)view withExposureIdentifier:(nullable NSString *)identifier;

@end

NS_ASSUME_NONNULL_END
