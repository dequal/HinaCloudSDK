//
// HNModuleManager.h
// HinaDataSDK
//
// Created by hina on 2022/8/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNModuleManager : NSObject <HNOpenURLProtocol>

+ (void)startWithConfigOptions:(HNConfigOptions *)configOptions;

+ (instancetype)sharedInstance;

- (BOOL)isDisableSDK;

/// 关闭所有的模块功能
- (void)disableAllModules;

/// 更新数据接收地址
/// @param serverURL 新的数据接收地址
- (void)updateServerURL:(NSString *)serverURL;
@end

#pragma mark -

@interface HNModuleManager (Property)

@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end

#pragma mark -

@interface HNModuleManager (ChannelMatch) <HNChannelMatchModuleProtocol>
@end

#pragma mark -

@interface HNModuleManager (DebugMode) <HNDebugModeModuleProtocol>

@end

#pragma mark -
@interface HNModuleManager (Encrypt) <HNEncryptModuleProtocol>

@property (nonatomic, strong, readonly) id<HNEncryptModuleProtocol> encryptManager;

@end

#pragma mark -

@interface HNModuleManager (DeepLink) <HNDeepLinkModuleProtocol>

@end

#pragma mark -

@interface HNModuleManager (AutoTrack) <HNAutoTrackModuleProtocol>

@end

#pragma mark -

@interface HNModuleManager (Visualized) <HNVisualizedModuleProtocol>

@end

#pragma mark -

@interface HNModuleManager (JavaScriptBridge) <HNJavaScriptBridgeModuleProtocol>

@end

@interface HNModuleManager (RemoteConfig) <HNRemoteConfigModuleProtocol>

@end

NS_ASSUME_NONNULL_END
