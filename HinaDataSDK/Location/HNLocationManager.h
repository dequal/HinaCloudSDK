//
// HNLocationManager.h
// HinaDataSDK
//
// Created by hina on 2022/5/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <CoreLocation/CoreLocation.h>
#import "HNModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNLocationManager : NSObject <HNPropertyModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) HNConfigOptions *configOptions;
@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end

@interface HNConfigOptions (Location)

@property (nonatomic, assign) BOOL enableLocation;

@end

NS_ASSUME_NONNULL_END
