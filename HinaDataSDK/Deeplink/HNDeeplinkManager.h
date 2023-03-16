//
// HNDeepLinkManager.h
// HinaDataSDK
//
// Created by hina on 2022/1/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNConfigOptions.h"
#import "HNModuleProtocol.h"
#import "HNDeepLinkProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNConfigOptions (DeepLinkPrivate)

@property (nonatomic, assign) BOOL enableDeepLink;

@end

@interface HNDeepLinkManager : NSObject <HNModuleProtocol, HNOpenURLProtocol, HNDeepLinkModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) HNConfigOptions *configOptions;

@property (nonatomic, copy) HNDeepLinkCompletion oldCompletion;
@property (nonatomic, copy) HNDeepLinkCompletion completion;

- (void)trackDeepLinkLaunchWithURL:(NSString *)url;

- (void)requestDeferredDeepLink:(NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
