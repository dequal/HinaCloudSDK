//
// HNRemoteConfigManager.h
// HinaDataSDK
//
// Created by hina on 2022/11/5.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNRemoteConfigCommonOperator.h"
#import "HNRemoteConfigCheckOperator.h"
#import "HNModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNConfigOptions (RemoteConfigPrivate)

@property (nonatomic, assign) BOOL enableRemoteConfig;

@end

@interface HNRemoteConfigManager : NSObject <HNModuleProtocol, HNOpenURLProtocol, HNRemoteConfigModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) HNConfigOptions *configOptions;

@end

NS_ASSUME_NONNULL_END
