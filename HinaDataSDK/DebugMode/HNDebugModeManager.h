//
// HNDebugModeManager.h
// HinaDataSDK
//
// Created by hina on 2022/11/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNModuleProtocol.h"
#import "HNConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNConfigOptions (DebugModePrivate)

@property (nonatomic, assign) HinaDataDebugMode debugMode;

@end

@interface HNDebugModeManager : NSObject <HNModuleProtocol, HNOpenURLProtocol, HNDebugModeModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) HNConfigOptions *configOptions;
@property (nonatomic) BOOL showDebugAlertView;

@end

NS_ASSUME_NONNULL_END
