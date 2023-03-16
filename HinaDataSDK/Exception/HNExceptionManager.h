//
// HNExceptionManager.h
// HinaDataSDK
//
// Created by hina on 2022/6/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNExceptionManager : NSObject <HNModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) HNConfigOptions *configOptions;

@end

NS_ASSUME_NONNULL_END
