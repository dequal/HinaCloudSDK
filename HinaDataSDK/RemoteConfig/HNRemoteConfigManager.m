//
// HNRemoteConfigManager.m
// HinaDataSDK
//
// Created by hina on 2022/11/5.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNRemoteConfigManager.h"
#import "HNConstants+Private.h"
#import "HinaDataSDK+Private.h"
#import "HNModuleManager.h"
#import "HNLog.h"
#import "HNConfigOptions+RemoteConfig.h"
#import "HNApplication.h"

@interface HNRemoteConfigManager ()

@property (atomic, strong) HNRemoteConfigOperator *operator;

@end

@implementation HNRemoteConfigManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNRemoteConfigManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNRemoteConfigManager alloc] init];
    });
    return manager;
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    if ([HNApplication  isAppExtension]) {
        configOptions.enableRemoteConfig = NO;
    }
    _configOptions = configOptions;
    self.enable = configOptions.enableRemoteConfig;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateWillChange:) name:kHNAppLifecycleStateWillChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - HNModuleProtocol

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        self.operator = [[HNRemoteConfigCommonOperator alloc] initWithConfigOptions:self.configOptions remoteConfigModel:nil];
        [self tryToRequestRemoteConfig];
    } else {
        self.operator = nil;
    }
}

#pragma mark - AppLifecycle

- (void)appLifecycleStateWillChange:(NSNotification *)sender {
    if (!self.isEnable) {
        return;
    }

    NSDictionary *userInfo = sender.userInfo;
    HNAppLifecycleState newState = [userInfo[kHNAppLifecycleNewStateKey] integerValue];
    HNAppLifecycleState oldState = [userInfo[kHNAppLifecycleOldStateKey] integerValue];

    // 热启动
    if (oldState != HNAppLifecycleStateInit && newState == HNAppLifecycleStateStart) {
        [self enableLocalRemoteConfig];
        [self tryToRequestRemoteConfig];
        return;
    }

    // 退出
    if (newState == HNAppLifecycleStateEnd) {
        [self cancelRequestRemoteConfig];
    }
}

#pragma mark - HNOpenURLProtocol

- (BOOL)canHandleURL:(NSURL *)url {
    return self.isEnable && [url.host isEqualToString:@"hinadataremoteconfig"];
}

- (BOOL)handleURL:(NSURL *)url {
    // 打开 log 用于调试
    [HinaDataSDK.sdkInstance enableLog:YES];

    [self cancelRequestRemoteConfig];

    if (![self.operator isKindOfClass:[HNRemoteConfigCheckOperator class]]) {
        HNRemoteConfigModel *model = self.operator.model;
        self.operator = [[HNRemoteConfigCheckOperator alloc] initWithConfigOptions:self.configOptions remoteConfigModel:model];
    }

    if ([self.operator respondsToSelector:@selector(handleRemoteConfigURL:)]) {
        return [self.operator handleRemoteConfigURL:url];
    }

    return NO;
}

- (void)cancelRequestRemoteConfig {
    if ([self.operator respondsToSelector:@selector(cancelRequestRemoteConfig)]) {
        [self.operator cancelRequestRemoteConfig];
    }
}

- (void)enableLocalRemoteConfig {
    if ([self.operator respondsToSelector:@selector(enableLocalRemoteConfig)]) {
        [self.operator enableLocalRemoteConfig];
    }
}

- (void)tryToRequestRemoteConfig {
    if ([self.operator respondsToSelector:@selector(tryToRequestRemoteConfig)]) {
        [self.operator tryToRequestRemoteConfig];
    }
}

#pragma mark - HNRemoteConfigModuleProtocol

- (BOOL)isDisableSDK {
    return self.operator.isDisableSDK;
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    if ([self.operator respondsToSelector:@selector(retryRequestRemoteConfigWithForceUpdateFlag:)]) {
        [self.operator retryRequestRemoteConfigWithForceUpdateFlag:isForceUpdate];
    }
}

- (BOOL)isIgnoreEventObject:(HNBaseEventObject *)obj {
    if (obj.isIgnoreRemoteConfig) {
        return NO;
    }

    if (self.operator.isDisableSDK) {
        HNLogDebug(@"【remote config】SDK is disabled");
        return YES;
    }

    if ([self.operator isBlackListContainsEvent:obj.event]) {
        HNLogDebug(@"【remote config】 %@ is ignored by remote config", obj.event);
        return YES;
    }

    return NO;
}

@end
