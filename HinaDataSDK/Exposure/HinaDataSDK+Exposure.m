//
// HinaDataSDK+Exposure.m
// HinaDataSDK
//
// Created by hina on 2022/8/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HinaDataSDK+Exposure.h"
#import "HNExposureManager.h"

@implementation HinaDataSDK (Exposure)

- (void)addExposureView:(UIView *)view withData:(HNExposureData *)data {
    [[HNExposureManager defaultManager] addExposureView:view withData:data];
}

- (void)removeExposureView:(UIView *)view withExposureIdentifier:(NSString *)identifier {
    [[HNExposureManager defaultManager] removeExposureView:view withExposureIdentifier:identifier];
}

@end
