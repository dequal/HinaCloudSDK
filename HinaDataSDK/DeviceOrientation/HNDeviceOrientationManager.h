//
// HNDeviceOrientationManager.h
// HinaDataSDK
//
// Created by hina on 2022/5/21.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <CoreMotion/CoreMotion.h>
#import "HNModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNConfigOptions (DeviceOrientation)

@property (nonatomic, assign) BOOL enableDeviceOrientation;

@end

@interface HNDeviceOrientationManager : NSObject <HNPropertyModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) HNConfigOptions *configOptions;
@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end

NS_ASSUME_NONNULL_END
