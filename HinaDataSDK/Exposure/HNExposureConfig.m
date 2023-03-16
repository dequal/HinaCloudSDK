//
// HNExposureConfig.m
// HinaDataSDK
//
// Created by hina on 2022/8/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNExposureConfig.h"

@interface HNExposureConfig () <NSCopying>

@property (nonatomic, assign) CGFloat areaRate;
@property (nonatomic, assign) NSTimeInterval stayDuration;
@property (nonatomic, assign) BOOL repeated;

@end

@implementation HNExposureConfig

- (instancetype)initWithAreaRate:(CGFloat)areaRate stayDuration:(NSTimeInterval)stayDuration repeated:(BOOL)repeated {
    self = [super init];
    if (self) {
        _areaRate = (areaRate >= 0 && areaRate <= 1 ? areaRate : 0);
        _stayDuration = (stayDuration >= 0 ? stayDuration : 0);
        _repeated = repeated;
    }
    return self;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone { 
    HNExposureConfig *config = [[[self class] allocWithZone:zone] init];
    config.areaRate = self.areaRate;
    config.stayDuration = self.stayDuration;
    config.repeated = self.repeated;
    return config;
}

@end
