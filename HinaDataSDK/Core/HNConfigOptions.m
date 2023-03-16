//
// HNConfigOptions.m
// HinaDataSDK
//
// Created by hina on 2022/4/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNConfigOptions.h"
#import "HinaDataSDK+Private.h"

#if __has_include("HNExposureConfig.h")
#import "HNExposureConfig.h"
#endif
#import "HNLimitKeyManager.h"

/// session 中事件最大间隔 5 分钟（单位为秒）
static const NSUInteger kHNSessionMaxInterval = 5 * 60;

@interface HNConfigOptions ()<NSCopying>

@property (atomic, strong, readwrite) NSMutableArray *encryptors;
@property (nonatomic, assign) BOOL enableTrackPush;

@property (nonatomic, assign) BOOL enableHeatMap;
@property (nonatomic, assign) BOOL enableVisualizedAutoTrack;
@property (nonatomic, assign) BOOL enableVisualizedProperties;

@property (nonatomic, assign) BOOL enableTrackAppCrash;

@property (nonatomic, assign) BOOL enableEncrypt;
@property (nonatomic, copy) void (^saveSecretKey)(HNSecretKey * _Nonnull secretKey);
@property (nonatomic, copy) HNSecretKey * _Nonnull (^loadSecretKey)(void);

@property (nonatomic, assign) BOOL enableSaveDeepLinkInfo;
@property (nonatomic, copy) NSArray<NSString *> *sourceChannels;
@property (nonatomic, assign) BOOL enableAutoAddChannelCallbackEvent;

/// 广告相关功能自定义地址
@property (nonatomic, copy) NSString *customADChannelURL;

@property (nonatomic) BOOL enableJavaScriptBridge;

@property (nonatomic, copy) NSString *remoteConfigURL;
@property (nonatomic, assign) BOOL disableRandomTimeRequestRemoteConfig;
@property (nonatomic, assign) NSInteger minRequestHourInterval;
@property (nonatomic, assign) NSInteger maxRequestHourInterval;

@property (nonatomic, assign) BOOL enableTrackPageLeave;
@property (nonatomic, assign) BOOL enableTrackChildPageLeave;
@property (nonatomic) BOOL enableAutoTrackChildViewScreen;
@property (nonatomic) HinaDataAutoTrackEventType autoTrackEventType;

//private switch
@property (nonatomic, assign) BOOL enableLocation;
@property (nonatomic, assign) BOOL enableDeviceOrientation;
@property (nonatomic, assign) BOOL enableRemoteConfig;
@property (nonatomic, assign) BOOL enableChannelMatch;
@property (nonatomic, assign) BOOL enableDeepLink;
@property (nonatomic, assign) BOOL enableAutoTrack;

#if __has_include("HNExposureConfig.h")
@property (nonatomic, copy) HNExposureConfig *exposureConfig;
#endif

@end

@implementation HNConfigOptions

#pragma mark - initialize
- (instancetype)initWithServerURL:(NSString *)serverURL launchOptions:(id)launchOptions {
    self = [super init];
    if (self) {
        _serverURL = serverURL;
        _launchOptions = launchOptions;
        _autoTrackEventType = HinaDataEventTypeNone;
        
        _flushInterval = 15 * 1000;
        _flushBulkSize = 100;
        _maxCacheSize = 10000;

        _minRequestHourInterval = 24;
        _maxRequestHourInterval = 48;

        _eventSessionTimeout = kHNSessionMaxInterval;

#ifdef HINA_ANALYTICS_ENABLE_AUTOTRACK_CHILD_VIEWSCREEN
        _enableAutoTrackChildViewScreen = YES;
#endif

        _flushNetworkPolicy =
#if TARGET_OS_IOS
        HinaDataNetworkType3G |
        HinaDataNetworkType4G |
#ifdef __IPHONE_14_1
        HinaDataNetworkType5G |
#endif
#endif
        HinaDataNetworkTypeWIFI;

        //default private switch
        _enableRemoteConfig = YES;
        _enableChannelMatch = YES;
        _enableDeepLink = YES;
        _enableAutoTrack = YES;

        _debugMode = HinaDataDebugOff;

        _storePlugins = [NSMutableArray array];
        _ignoredPageLeaveClasses = [NSSet set];
        _propertyPlugins = [NSMutableArray array];
#if __has_include("HNExposureConfig.h")
        _exposureConfig = [[HNExposureConfig alloc] initWithAreaRate:0 stayDuration:0 repeated:YES];
#endif
    }
    return self;
}

#pragma mark NSCopying
- (id)copyWithZone:(nullable NSZone *)zone {
    HNConfigOptions *options = [[[self class] allocWithZone:zone] init];
    options.serverURL = self.serverURL;
    options.launchOptions = self.launchOptions;
    options.enableJavaScriptBridge = self.enableJavaScriptBridge;
    options.flushInterval = self.flushInterval;
    options.flushBulkSize = self.flushBulkSize;
    options.maxCacheSize = self.maxCacheSize;
    options.enableLog = self.enableLog;
    options.flushBeforeEnterBackground = self.flushBeforeEnterBackground;
    options.flushNetworkPolicy = self.flushNetworkPolicy;
    options.disableSDK = self.disableSDK;
    options.storePlugins = self.storePlugins;
    options.enableSession = self.enableSession;
    options.eventSessionTimeout = self.eventSessionTimeout;
    options.disableDeviceId = self.disableDeviceId;
    options.propertyPlugins = self.propertyPlugins;
    options.instantEvents = self.instantEvents;

#if TARGET_OS_IOS
    // 支持 https 自签证书
    options.securityPolicy = [self.securityPolicy copy];

    // 远程控制
    options.minRequestHourInterval = self.minRequestHourInterval;
    options.maxRequestHourInterval = self.maxRequestHourInterval;
    options.remoteConfigURL = self.remoteConfigURL;
    options.disableRandomTimeRequestRemoteConfig = self.disableRandomTimeRequestRemoteConfig;
    // 加密
    options.encryptors = self.encryptors;
    options.enableEncrypt = self.enableEncrypt;
    options.saveSecretKey = self.saveSecretKey;
    options.loadSecretKey = self.loadSecretKey;
    // 全埋点
    options.autoTrackEventType = self.autoTrackEventType;
    options.enableAutoTrackChildViewScreen = self.enableAutoTrackChildViewScreen;
    options.enableHeatMap = self.enableHeatMap;
    options.enableVisualizedAutoTrack = self.enableVisualizedAutoTrack;
    options.enableVisualizedProperties = self.enableVisualizedProperties;

    // Crash 采集
    options.enableTrackAppCrash = self.enableTrackAppCrash;
    // 渠道相关
    options.enableSaveDeepLinkInfo = self.enableSaveDeepLinkInfo;
    options.sourceChannels = self.sourceChannels;
    options.enableAutoAddChannelCallbackEvent = self.enableAutoAddChannelCallbackEvent;
    // 推送点击
    options.enableTrackPush = self.enableTrackPush;
    // 页面浏览时长
    options.enableTrackPageLeave = self.enableTrackPageLeave;
    options.enableTrackChildPageLeave = self.enableTrackChildPageLeave;
    options.ignoredPageLeaveClasses = self.ignoredPageLeaveClasses;

    //private switch
    options.enableRemoteConfig = self.enableRemoteConfig;
    options.enableChannelMatch = self.enableChannelMatch;
    options.enableDeepLink = self.enableDeepLink;
    options.enableAutoTrack = self.enableAutoTrack;
    options.customADChannelURL = self.customADChannelURL;
#if __has_include("HNExposureConfig.h")
    options.exposureConfig = self.exposureConfig;
#endif
#endif
    
    return options;
}

#pragma mark set
- (void)setFlushInterval:(NSInteger)flushInterval {
    _flushInterval = flushInterval >= 5000 ? flushInterval : 5000;
}

- (void)setFlushBulkSize:(NSInteger)flushBulkSize {
    _flushBulkSize = flushBulkSize >= 50 ? flushBulkSize : 50;
}

- (void)setMaxCacheSize:(NSInteger)maxCacheSize {
    //防止设置的值太小导致事件丢失
    _maxCacheSize = maxCacheSize >= 10000 ? maxCacheSize : 10000;
}

- (void)setMinRequestHourInterval:(NSInteger)minRequestHourInterval {
    if (minRequestHourInterval > 0) {
        _minRequestHourInterval = MIN(minRequestHourInterval, 7*24);
    }
}

- (void)setMaxRequestHourInterval:(NSInteger)maxRequestHourInterval {
    if (maxRequestHourInterval > 0) {
        _maxRequestHourInterval = MIN(maxRequestHourInterval, 7*24);
    }
}

- (void)setEventSessionTimeout:(NSInteger)eventSessionTimeout {
    if (eventSessionTimeout > 0) {
        _eventSessionTimeout = eventSessionTimeout;
    }
}

- (void)setInstantEvents:(NSArray<NSString *> *)instantEvents {
    if ([instantEvents isKindOfClass:[NSArray class]]) {
        _instantEvents = instantEvents;
    }
}

- (void)registerStorePlugin:(id<HNStorePlugin>)plugin {
    [self.storePlugins addObject:plugin];
}

- (void)ignorePageLeave:(NSArray<Class> *)viewControllers {
    if (![viewControllers isKindOfClass:[NSArray class]]) {
        return;
    }
    self.ignoredPageLeaveClasses = [NSSet setWithArray:viewControllers];
}

- (void)registerPropertyPlugin:(HNPropertyPlugin *)plugin {
    if (![plugin isKindOfClass:HNPropertyPlugin.class]) {
        return;
    }
    [self.propertyPlugins addObject:plugin];
}

- (void)registerLimitKeys:(NSDictionary<HNLimitKey, NSString *> *)keys {
    [HNLimitKeyManager registerLimitKeys:keys];
}

@end


