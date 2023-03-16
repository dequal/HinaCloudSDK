//
// HNModuleManager.m
// HinaDataSDK
//
// Created by hina on 2022/8/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNModuleManager.h"
#import "HNModuleProtocol.h"
#import "HNConfigOptions.h"
#import "HinaDataSDK+Private.h"
#import "HNThreadSafeDictionary.h"

// Location 模块名
static NSString * const kHNLocationModuleName = @"Location";
static NSString * const kHNDeviceOrientationModuleName = @"DeviceOrientation";
static NSString * const kHNDebugModeModuleName = @"DebugMode";
static NSString * const kHNChannelMatchModuleName = @"ChannelMatch";
/// 可视化相关（可视化全埋点和点击图）
static NSString * const kHNVisualizedModuleName = @"Visualized";

static NSString * const kHNEncryptModuleName = @"Encrypt";
static NSString * const kHNDeepLinkModuleName = @"DeepLink";
static NSString * const kHNNotificationModuleName = @"AppPush";
static NSString * const kHNAutoTrackModuleName = @"AutoTrack";
static NSString * const kHNRemoteConfigModuleName = @"RemoteConfig";

static NSString * const kHNJavaScriptBridgeModuleName = @"JavaScriptBridge";
static NSString * const kHNExceptionModuleName = @"Exception";
static NSString * const kHNExposureModuleName = @"Exposure";

@interface HNModuleManager ()

/// 已开启的模块
@property (nonatomic, strong) NSArray<NSString *> *moduleNames;

@property (nonatomic, strong) HNConfigOptions *configOptions;

@end

@implementation HNModuleManager

+ (void)startWithConfigOptions:(HNConfigOptions *)configOptions {
    HNModuleManager.sharedInstance.configOptions = configOptions;
    [[HNModuleManager sharedInstance] loadModulesWithConfigOptions:configOptions];
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HNModuleManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNModuleManager alloc] init];
    });
    return manager;
}

#pragma mark - Private
- (NSString *)classNameForModule:(NSString *)moduleName {
    return [NSString stringWithFormat:@"HN%@Manager", moduleName];
}

- (id)moduleWithName:(NSString *)moduleName {
    NSString *className = [self classNameForModule: moduleName];
    Class moduleClass = NSClassFromString(className);
    if (!moduleClass) {
        return nil;
    }
    SEL sharedManagerSEL = NSSelectorFromString(@"defaultManager");
    if (![moduleClass respondsToSelector:sharedManagerSEL]) {
        return nil;
    }
    id (*sharedManager)(id, SEL) = (id (*)(id, SEL))[moduleClass methodForSelector:sharedManagerSEL];

    id module = sharedManager(moduleClass, sharedManagerSEL);
    return module;
}

// module加载
- (void)loadModulesWithConfigOptions:(HNConfigOptions *)configOptions {
    [self loadModule:kHNJavaScriptBridgeModuleName withConfigOptions:configOptions];
    // 禁止 SDK 时，不开启其他模块
    if (configOptions.disableSDK) {
        return;
    }
#if TARGET_OS_IOS
    for (NSString *moduleName in self.moduleNames) {
        if ([moduleName isEqualToString:kHNJavaScriptBridgeModuleName]) {
            continue;
        }
        [self loadModule:moduleName withConfigOptions:configOptions];
    }
#endif
}

- (void)loadModule:(NSString *)moduleName withConfigOptions:(HNConfigOptions *)configOptions {
    if (!moduleName) {
        return;
    }
    id module = [self moduleWithName:moduleName];
    if (!module) {
        return;
    }
    if ([module conformsToProtocol:@protocol(HNModuleProtocol)] && [module respondsToSelector:@selector(setConfigOptions:)]) {
        id<HNModuleProtocol>moduleObject = (id<HNModuleProtocol>)module;
        moduleObject.configOptions = configOptions;
    }
}

- (NSArray<NSString *> *)moduleNames {
    return @[kHNJavaScriptBridgeModuleName, kHNNotificationModuleName, kHNChannelMatchModuleName,
             kHNDeepLinkModuleName, kHNDebugModeModuleName, kHNLocationModuleName,
             kHNAutoTrackModuleName, kHNVisualizedModuleName, kHNEncryptModuleName,
             kHNDeviceOrientationModuleName, kHNExceptionModuleName, kHNRemoteConfigModuleName, kHNExposureModuleName];
}

#pragma mark - Public

- (BOOL)isDisableSDK {
    if (self.configOptions.disableSDK) {
        return YES;
    }
    id module = [self moduleWithName:kHNRemoteConfigModuleName];
    if ([module conformsToProtocol:@protocol(HNRemoteConfigModuleProtocol)] && [module conformsToProtocol:@protocol(HNModuleProtocol)]) {
        id<HNRemoteConfigModuleProtocol, HNModuleProtocol> manager = module;
        return manager.isEnable ? manager.isDisableSDK : NO;
    }
    return NO;
}

- (void)disableAllModules {
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            continue;
        }
        if ([module conformsToProtocol:@protocol(HNModuleProtocol)] && [module respondsToSelector:@selector(setEnable:)]) {
            id<HNModuleProtocol>moduleObject = module;
            moduleObject.enable = NO;
        }
    }
}

- (void)updateServerURL:(NSString *)serverURL {
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            continue;
        }
        if ([module conformsToProtocol:@protocol(HNModuleProtocol)] && [module respondsToSelector:@selector(isEnable)] && [module respondsToSelector:@selector(updateServerURL:)]) {
            id<HNModuleProtocol>moduleObject = module;
            moduleObject.isEnable ? [module updateServerURL:serverURL] : nil;
        }
    }
}

#pragma mark - Open URL

- (BOOL)canHandleURL:(NSURL *)url {
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            continue;
        }
        if (![module conformsToProtocol:@protocol(HNOpenURLProtocol)]) {
            continue;
        }
        if (![module respondsToSelector:@selector(canHandleURL:)]) {
            continue;
        }
        id<HNOpenURLProtocol>moduleObject = module;
        if ([moduleObject canHandleURL:url]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)handleURL:(NSURL *)url {
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            continue;
        }
        if (![module conformsToProtocol:@protocol(HNOpenURLProtocol)]) {
            continue;
        }
        if (![module respondsToSelector:@selector(canHandleURL:)] || ![module respondsToSelector:@selector(handleURL:)]) {
            continue;
        }
        id<HNOpenURLProtocol>moduleObject = module;
        if ([moduleObject canHandleURL:url]) {
            return [moduleObject handleURL:url];
        }
    }
    return NO;
}

@end

#pragma mark -

@implementation HNModuleManager (Property)

- (NSDictionary *)properties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    // 兼容使用宏定义的方式源码集成 SDK
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            continue;
        }
        if (![module conformsToProtocol:@protocol(HNPropertyModuleProtocol)] || ![module conformsToProtocol:@protocol(HNModuleProtocol)]) {
            continue;
        }
        if (![module respondsToSelector:@selector(properties)] && [module respondsToSelector:@selector(isEnable)]) {
            continue;
        }
        id<HNPropertyModuleProtocol, HNModuleProtocol>moduleObject = module;
        if (!moduleObject.isEnable) {
            continue;
        }
#ifndef HINA_ANALYTICS_DIHNBLE_TRACK_GPS
        if ([moduleName isEqualToString:kHNLocationModuleName]) {
            [properties addEntriesFromDictionary:moduleObject.properties];
            continue;
        }
#endif
#ifndef HINA_ANALYTICS_DIHNBLE_TRACK_DEVICE_ORIENTATION
        if ([moduleName isEqualToString:kHNDeviceOrientationModuleName]) {
            [properties addEntriesFromDictionary:moduleObject.properties];
            continue;
        }
#endif
        if (moduleObject.properties.count > 0) {
            [properties addEntriesFromDictionary:moduleObject.properties];
        }
    }
    return properties;
}

@end

#pragma mark -

@implementation HNModuleManager (ChannelMatch)

- (id<HNChannelMatchModuleProtocol>)channelMatchManager {
    id module = [self moduleWithName:kHNChannelMatchModuleName];
    if ([module conformsToProtocol:@protocol(HNChannelMatchModuleProtocol)] && [module conformsToProtocol:@protocol(HNModuleProtocol)]) {
        id<HNChannelMatchModuleProtocol, HNModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (NSDictionary *)channelInfoWithEvent:(NSString *)event {
    return [self.channelMatchManager channelInfoWithEvent:event];
}

@end

#pragma mark -

@implementation HNModuleManager (DebugMode)

- (id<HNDebugModeModuleProtocol>)debugModeManager {
    id module = [self moduleWithName:kHNDebugModeModuleName];
    if ([module conformsToProtocol:@protocol(HNDebugModeModuleProtocol)] && [module conformsToProtocol:@protocol(HNModuleProtocol)]) {
        id<HNDebugModeModuleProtocol, HNModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (void)setShowDebugAlertView:(BOOL)isShow {
    [self.debugModeManager setShowDebugAlertView:isShow];
}

- (void)showDebugModeWarning:(NSString *)message {
    [self.debugModeManager showDebugModeWarning:message];
}

@end

#pragma mark -
@implementation HNModuleManager (Encrypt)

- (id<HNEncryptModuleProtocol>)encryptManager {
    id module = [self moduleWithName:kHNEncryptModuleName];
    if ([module conformsToProtocol:@protocol(HNEncryptModuleProtocol)] && [module conformsToProtocol:@protocol(HNModuleProtocol)]) {
        id<HNEncryptModuleProtocol, HNModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (BOOL)hasSecretKey {
    return self.encryptManager.hasSecretKey;
}

- (nullable NSDictionary *)encryptJSONObject:(nonnull id)obj {
    return [self.encryptManager encryptJSONObject:obj];
}

- (void)handleEncryptWithConfig:(nonnull NSDictionary *)encryptConfig {
    [self.encryptManager handleEncryptWithConfig:encryptConfig];
}

@end

#pragma mark -

@implementation HNModuleManager (DeepLink)

- (id<HNDeepLinkModuleProtocol>)deepLinkManager {
    id module = [self moduleWithName:kHNDeepLinkModuleName];
    if ([module conformsToProtocol:@protocol(HNDeepLinkModuleProtocol)] && [module conformsToProtocol:@protocol(HNModuleProtocol)]) {
        id<HNDeepLinkModuleProtocol, HNModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (NSDictionary *)latestUtmProperties {
    return self.deepLinkManager.latestUtmProperties;
}

- (NSDictionary *)utmProperties {
    return self.deepLinkManager.utmProperties;
}

- (void)clearUtmProperties {
    [self.deepLinkManager clearUtmProperties];
}

@end

#pragma mark -

@implementation HNModuleManager (AutoTrack)

- (id<HNAutoTrackModuleProtocol>)autoTrackManager {
    id module = [self moduleWithName:kHNAutoTrackModuleName];
    if ([module conformsToProtocol:@protocol(HNAutoTrackModuleProtocol)] && [module conformsToProtocol:@protocol(HNModuleProtocol)]) {
        id<HNAutoTrackModuleProtocol, HNModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (void)trackAppEndWhenCrashed {
    [self.autoTrackManager trackAppEndWhenCrashed];
}

- (void)trackPageLeaveWhenCrashed {
    [self.autoTrackManager trackPageLeaveWhenCrashed];
}

@end

#pragma mark -

@implementation HNModuleManager (Visualized)

- (id<HNVisualizedModuleProtocol>)visualizedManager {
    id module = [self moduleWithName:kHNVisualizedModuleName];
    if ([module conformsToProtocol:@protocol(HNVisualizedModuleProtocol)] && [module conformsToProtocol:@protocol(HNModuleProtocol)]) {
        id<HNVisualizedModuleProtocol, HNModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

#pragma mark properties
// 采集元素属性
- (nullable NSDictionary *)propertiesWithView:(id)view {
    return [self.visualizedManager propertiesWithView:view];
}

#pragma mark visualProperties
// 采集元素自定义属性
- (void)visualPropertiesWithView:(id)view completionHandler:(void (^)(NSDictionary *_Nullable))completionHandler {
    id<HNVisualizedModuleProtocol> manager = self.visualizedManager;
    if (!manager) {
        return completionHandler(nil);
    }
    [self.visualizedManager visualPropertiesWithView:view completionHandler:completionHandler];
}

// 根据属性配置，采集 App 属性值
- (void)queryVisualPropertiesWithConfigs:(NSArray <NSDictionary *>*)propertyConfigs completionHandler:(void (^)(NSDictionary *_Nullable properties))completionHandler {
    id<HNVisualizedModuleProtocol> manager = self.visualizedManager;
    if (!manager) {
        return completionHandler(nil);
    }
    [manager queryVisualPropertiesWithConfigs:propertyConfigs completionHandler:completionHandler];
}

@end

#pragma mark -

@implementation HNModuleManager (JavaScriptBridge)

- (NSString *)javaScriptSource {
    NSMutableString *source = [NSMutableString string];
    for (NSString *moduleName in self.moduleNames) {
        id module = [self moduleWithName:moduleName];
        if (!module) {
            continue;
        }
        if ([module conformsToProtocol:@protocol(HNJavaScriptBridgeModuleProtocol)] && [module respondsToSelector:@selector(javaScriptSource)] && [module conformsToProtocol:@protocol(HNModuleProtocol)]) {
            id<HNJavaScriptBridgeModuleProtocol, HNModuleProtocol>moduleObject = module;
            NSString *javaScriptSource = [moduleObject javaScriptSource];
            if (javaScriptSource.length <= 0) {
                continue;
            }
            if ([moduleName isEqualToString:kHNJavaScriptBridgeModuleName] || moduleObject.isEnable) {
                [source appendString:javaScriptSource];
            }
        }
    }
    return source;
}

@end

@implementation HNModuleManager (RemoteConfig)

- (id<HNRemoteConfigModuleProtocol>)remoteConfigManager {
    id module = [self moduleWithName:kHNRemoteConfigModuleName];
    if ([module conformsToProtocol:@protocol(HNRemoteConfigModuleProtocol)] && [module conformsToProtocol:@protocol(HNModuleProtocol)]) {
        id<HNRemoteConfigModuleProtocol, HNModuleProtocol> manager = module;
        return manager.isEnable ? manager : nil;
    }
    return nil;
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    [self.remoteConfigManager retryRequestRemoteConfigWithForceUpdateFlag:isForceUpdate];
}

- (BOOL)isIgnoreEventObject:(HNBaseEventObject *)obj {
    return [self.remoteConfigManager isIgnoreEventObject:obj];
}

@end
