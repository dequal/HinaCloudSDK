//
// HinaDataSDK.m
// HinaDataSDK
//
// Created by hina on 15/7/1.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HinaDataSDK.h"
#import "HNKeyChainItemWrapper.h"
#import "HNCommonUtility.h"
#import "HNConstants+Private.h"
#import "HinaDataSDK+Private.h"
#import "HNTrackTimer.h"
#import "HNReachability.h"
#import "HNIdentifier.h"
#import "HNValidator.h"
#import "HNLog+Private.h"
#import "HNConsoleLogger.h"
#import "HNModuleManager.h"
#import "HNAppLifecycle.h"
#import "HNReferrerManager.h"
#import "HNProfileEventObject.h"
#import "HNItemEventObject.h"
#import "HNJSONUtil.h"
#import "HNPropertyPluginManager.h"
#import "HNPresetPropertyPlugin.h"
#import "HNAppVersionPropertyPlugin.h"
#import "HNDeviceIDPropertyPlugin.h"
#import "HNApplication.h"
#import "HNEventTrackerPluginManager.h"
#import "HNStoreManager.h"
#import "HNFileStorePlugin.h"
#import "HNUserDefaultsStorePlugin.h"
#import "HNSessionProperty.h"
#import "HNFlowManager.h"
#import "HNNetworkInfoPropertyPlugin.h"
#import "HNCarrierNamePropertyPlugin.h"
#import "HNEventObjectFactory.h"
#import "HNSuperPropertyPlugin.h"
#import "HNDynamicSuperPropertyPlugin.h"
#import "HNReferrerTitlePropertyPlugin.h"
#import "HNEventDurationPropertyPlugin.h"
#import "HNFirstDayPropertyPlugin.h"
#import "HNModulePropertyPlugin.h"
#import "HNSessionPropertyPlugin.h"
#import "HNEventStore.h"
#import "HNLimitKeyManager.h"
#import "NSDictionary+HNCopyProperties.h"

#define VERSION @"1.0.0"

void *HinaDataQueueTag = &HinaDataQueueTag;

static dispatch_once_t sdkInitializeOnceToken;
static HinaDataSDK *sharedInstance = nil;
NSString * const HinaDataIdentityKeyIDFA = @"H_identity_idfa";
NSString * const HinaDataIdentityKeyMobile = @"H_identity_mobile";
NSString * const HinaDataIdentityKeyEmail = @"H_identity_email";

@interface HinaDataSDK()

@property (nonatomic, strong) HNNetwork *network;

@property (nonatomic, strong) HNEventStore *eventStore;

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, strong) dispatch_queue_t readWriteQueue;

@property (nonatomic, strong) HNTrackTimer *trackTimer;

@property (nonatomic, strong) NSTimer *timer;

// 兼容 UA 值打通逻辑，后续废弃 UA 值打通逻辑时可以全部移除
@property (atomic, copy) NSString *userAgent;
@property (nonatomic, copy) NSString *addWebViewUserAgent;

@property (nonatomic, strong) HNConfigOptions *configOptions;

@property (nonatomic, copy) BOOL (^trackEventCallback)(NSString *, NSMutableDictionary<NSString *, id> *);

@property (nonatomic, strong) HNIdentifier *identifier;

@property (nonatomic, strong) HNSessionProperty *sessionProperty;

@property (atomic, strong) HNConsoleLogger *consoleLogger;

@property (nonatomic, strong) HNAppLifecycle *appLifecycle;

@end

@implementation HinaDataSDK

#pragma mark - Initialization
+ (void)startWithConfigOptions:(HNConfigOptions *)configOptions {
    NSAssert(hinadata_is_same_queue(dispatch_get_main_queue()), @"The iOS SDK must be initialized in the main thread, otherwise it will cause unexpected problems (such as missing H_AppStart event).");
    
    dispatch_once(&sdkInitializeOnceToken, ^{
        sharedInstance = [[HinaDataSDK alloc] initWithConfigOptions:configOptions];
        [HNModuleManager startWithConfigOptions:sharedInstance.configOptions];
        [sharedInstance addAppLifecycleObservers];
    });
}

+ (HinaDataSDK *_Nullable)sharedInstance {
    if ([HNModuleManager.sharedInstance isDisableSDK]) {
        HNLogDebug(@"SDK is disabled");
        return nil;
    }
    return sharedInstance;
}

+ (HinaDataSDK *)sdkInstance {
    return sharedInstance;
}

+ (void)disableSDK {
    HinaDataSDK *instance = HinaDataSDK.sdkInstance;
    if (instance.configOptions.disableSDK) {
        return;
    }
    [instance track:@"H_AppDataTrackingClose"];
    [instance flush];
    
    [instance clearTrackTimer];
    [instance stopFlushTimer];
    [instance removeObservers];
    [instance removeWebViewUserAgent];
    
    [HNReachability.sharedInstance stopMonitoring];
    
    [HNModuleManager.sharedInstance disableAllModules];
    
    instance.configOptions.disableSDK = YES;
    
    //disable all event tracker plugins
    [[HNEventTrackerPluginManager defaultManager] disableAllPlugins];
    
    HNLogWarn(@"HinaDataSDK disabled");
    [HNLog sharedLog].enableLog = NO;
}

+ (void)enableSDK {
    HinaDataSDK *instance = HinaDataSDK.sdkInstance;
    if (!instance.configOptions.disableSDK) {
        return;
    }
    instance.configOptions.disableSDK = NO;
    // 部分模块和监听依赖网络状态，所以需要优先开启
    [HNReachability.sharedInstance startMonitoring];
    
    // 优先添加远程控制监听，防止热启动时关闭 SDK 的情况下
    [instance addRemoteConfigObservers];
    
    if (instance.configOptions.enableLog) {
        [instance enableLog:YES];
    }
    
    [HNModuleManager startWithConfigOptions:instance.configOptions];
    
    // 需要在模块加载完成之后添加监听，如果过早会导致退到后台后，H_AppEnd 事件无法立即上报
    [instance addAppLifecycleObservers];
    
    [instance appendWebViewUserAgent];
    [instance startFlushTimer];
    
    //enable all event tracker plugins
    [[HNEventTrackerPluginManager defaultManager] enableAllPlugins];
    
    HNLogInfo(@"HinaDataSDK enabled");
}

- (instancetype)initWithConfigOptions:(nonnull HNConfigOptions *)configOptions {
    @try {
        self = [super init];
        if (self) {
            _configOptions = [configOptions copy];
            
            // 优先开启 log, 防止部分日志输出不生效(比如: HNIdentifier 初始化时校验 loginIDKey)
            if (!_configOptions.disableSDK && _configOptions.enableLog) {
                [self enableLog:_configOptions.enableLog];
            }
            
            [self resgisterStorePlugins];
            
            _appLifecycle = [[HNAppLifecycle alloc] init];
            
            NSString *serialQueueLabel = [NSString stringWithFormat:@"com.hinadata.serialQueue.%p", self];
            _serialQueue = dispatch_queue_create([serialQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
            dispatch_queue_set_specific(_serialQueue, HinaDataQueueTag, &HinaDataQueueTag, NULL);
            
            NSString *readWriteQueueLabel = [NSString stringWithFormat:@"com.hinadata.readWriteQueue.%p", self];
            _readWriteQueue = dispatch_queue_create([readWriteQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
            
            _network = [[HNNetwork alloc] init];
            
            NSString *path = [HNFileStorePlugin filePath:kHNDatabaseDefaultFileName];
            _eventStore = [HNEventStore eventStoreWithFilePath:path];
            
            _trackTimer = [[HNTrackTimer alloc] init];
            
            _identifier = [[HNIdentifier alloc] initWithQueue:_readWriteQueue];
            
            if (_configOptions.enableSession) {
                _sessionProperty = [[HNSessionProperty alloc] initWithMaxInterval:_configOptions.eventSessionTimeout * 1000];
            } else {
                [HNSessionProperty removeSessionModel];
            }
            
            // 初始化注册内部插件
            [self registerPropertyPlugin];
            
            if (!_configOptions.disableSDK) {
                [[HNReachability sharedInstance] startMonitoring];
                [self addRemoteConfigObservers];
            }
            
#if TARGET_OS_IOS
            [self setupSecurityPolicyWithConfigOptions:_configOptions];
            
            [HNReferrerManager sharedInstance].serialQueue = _serialQueue;
#endif
            //start flush timer for App Extension
            if ([HNApplication isAppExtension]) {
                [self startFlushTimer];
            }
            
            [HNFlowManager sharedInstance].configOptions = self.configOptions;
            
            [HNFlowManager.sharedInstance loadFlows];
        }
        
    } @catch(NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resgisterStorePlugins {
    HNFileStorePlugin *filePlugin = [[HNFileStorePlugin alloc] init];
    [[HNStoreManager sharedInstance] registerStorePlugin:filePlugin];
    
    HNUserDefaultsStorePlugin *userDefaultsPlugin = [[HNUserDefaultsStorePlugin alloc] init];
    [[HNStoreManager sharedInstance] registerStorePlugin:userDefaultsPlugin];
    
    for (id<HNStorePlugin> plugin in self.configOptions.storePlugins) {
        [[HNStoreManager sharedInstance] registerStorePlugin:plugin];
    }
}

- (void)removeObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)registerPropertyPlugin {
    HNNetworkInfoPropertyPlugin *networkInfoPlugin = [[HNNetworkInfoPropertyPlugin alloc] init];
    HNCarrierNamePropertyPlugin *carrierPlugin = [[HNCarrierNamePropertyPlugin alloc] init];
    
    dispatch_async(self.serialQueue, ^{
        // 注册 configOptions 中自定义属性插件
        for (HNPropertyPlugin * plugin in self.configOptions.propertyPlugins) {
            [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:plugin];
        }
        
        // 预置属性
        HNPresetPropertyPlugin *presetPlugin = [[HNPresetPropertyPlugin alloc] initWithLibVersion:VERSION];
        [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:presetPlugin];
        
        // 应用版本
        HNAppVersionPropertyPlugin *appVersionPlugin = [[HNAppVersionPropertyPlugin alloc] init];
        [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:appVersionPlugin];
        
        // deviceID，super 优先级，不能被覆盖
        HNDeviceIDPropertyPlugin *deviceIDPlugin = [[HNDeviceIDPropertyPlugin alloc] init];
        deviceIDPlugin.disableDeviceId = self.configOptions.disableDeviceId;
        [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:deviceIDPlugin];
        
        // 运营商信息
        [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:carrierPlugin];
        
        // 注册静态公共属性插件
        HNSuperPropertyPlugin *superPropertyPlugin = [[HNSuperPropertyPlugin alloc] init];
        [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:superPropertyPlugin];
        
        // 动态公共属性
        HNDynamicSuperPropertyPlugin *dynamicSuperPropertyPlugin = [HNDynamicSuperPropertyPlugin sharedDynamicSuperPropertyPlugin];
        [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:dynamicSuperPropertyPlugin];
        
        // 网络相关信息
        [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:networkInfoPlugin];
        
        // 事件时长，根据 event 计算，不支持 H5
        HNEventDurationPropertyPlugin *eventDurationPropertyPlugin = [[HNEventDurationPropertyPlugin alloc] initWithTrackTimer:self.trackTimer];
        [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:eventDurationPropertyPlugin];
        
        // ReferrerTitle
        HNReferrerTitlePropertyPlugin *referrerTitlePropertyPlugin = [[HNReferrerTitlePropertyPlugin alloc] init];
        [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:referrerTitlePropertyPlugin];
        
        // IsFirstDay
        HNFirstDayPropertyPlugin *firstDayPropertyPlugin = [[HNFirstDayPropertyPlugin alloc] initWithQueue:self.readWriteQueue];
        [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:firstDayPropertyPlugin];
        
        // HNModuleManager.sharedInstance.properties
        HNModulePropertyPlugin *modulePropertyPlugin = [[HNModulePropertyPlugin alloc] init];
        [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:modulePropertyPlugin];
        
        // sessionProperty
        if (self.sessionProperty) {
            HNSessionPropertyPlugin *sessionPropertyPlugin = [[HNSessionPropertyPlugin alloc] initWithSessionProperty:self.sessionProperty];
            [[HNPropertyPluginManager sharedInstance] registerPropertyPlugin:sessionPropertyPlugin];
        }
    });
}

#if TARGET_OS_IOS
- (void)setupSecurityPolicyWithConfigOptions:(HNConfigOptions *)options {
    HNSecurityPolicy *securityPolicy = options.securityPolicy;
    if (!securityPolicy) {
        return;
    }
    
#ifdef DEBUG
    NSURL *serverURL = [NSURL URLWithString:options.serverURL];
    if (securityPolicy.SSLPinningMode != HNSSLPinningModeNone && ![serverURL.scheme isEqualToString:@"https"]) {
        NSString *pinningMode = @"Unknown Pinning Mode";
        switch (securityPolicy.SSLPinningMode) {
            case HNSSLPinningModeNone:
                pinningMode = @"HNSSLPinningModeNone";
                break;
            case HNSSLPinningModeCertificate:
                pinningMode = @"HNSSLPinningModeCertificate";
                break;
            case HNSSLPinningModePublicKey:
                pinningMode = @"HNSSLPinningModePublicKey";
                break;
        }
        NSString *reason = [NSString stringWithFormat:@"A security policy configured with `%@` can only be applied on a manager with a secure base URL (i.e. https)", pinningMode];
        @throw [NSException exceptionWithName:@"Invalid Security Policy" reason:reason userInfo:nil];
    }
#endif
    
    HNHTTPSession.sharedInstance.securityPolicy = securityPolicy;
}
#endif

- (void)enableLoggers {
    if (!self.consoleLogger) {
        HNConsoleLogger *consoleLogger = [[HNConsoleLogger alloc] init];
        [HNLog addLogger:consoleLogger];
        self.consoleLogger = consoleLogger;
    }
}

+ (UInt64)getCurrentTime {
    return [[NSDate date] timeIntervalSince1970] * 1000;
}

+ (UInt64)getSystemUpTime {
    return NSProcessInfo.processInfo.systemUptime * 1000;
}

- (NSDictionary *)getPresetProperties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    void(^block)(void) = ^{
        NSDictionary *dic = [[HNPropertyPluginManager sharedInstance] currentPropertiesForPluginClasses:@[HNPresetPropertyPlugin.class, HNDeviceIDPropertyPlugin.class, HNCarrierNamePropertyPlugin.class, HNNetworkInfoPropertyPlugin.class, HNFirstDayPropertyPlugin.class, HNAppVersionPropertyPlugin.class]];
        [properties addEntriesFromDictionary:dic];
    };
    if (hinadata_is_same_queue(self.serialQueue)) {
        block();
    } else {
        dispatch_sync(self.serialQueue, block);
    }
    return properties;
}

- (void)setServerUrl:(NSString *)serverUrl {
#if TARGET_OS_OSX
    if (serverUrl && ![serverUrl isKindOfClass:[NSString class]]) {
        HNLogError(@"%@ serverUrl must be NSString, please check the value!", self);
        return;
    }
    // macOS 暂不支持远程控制，即不支持 setServerUrl: isRequestRemoteConfig: 接口
    dispatch_async(self.serialQueue, ^{
        self.configOptions.serverURL = serverUrl;
    });
#else
    [self setServerUrl:serverUrl isRequestRemoteConfig:NO];
#endif
}

- (NSString *)serverUrl {
    return self.configOptions.serverURL;
}

- (void)setServerUrl:(NSString *)serverUrl isRequestRemoteConfig:(BOOL)isRequestRemoteConfig {
    if (serverUrl && ![serverUrl isKindOfClass:[NSString class]]) {
        HNLogError(@"%@ serverUrl must be NSString, please check the value!", self);
        return;
    }
    
    dispatch_async(self.serialQueue, ^{
        if (![self.configOptions.serverURL isEqualToString:serverUrl]) {
            self.configOptions.serverURL = serverUrl;
            
            // 更新数据接收地址
            [HNModuleManager.sharedInstance updateServerURL:serverUrl];
        }
        
        if (isRequestRemoteConfig) {
            [HNModuleManager.sharedInstance retryRequestRemoteConfigWithForceUpdateFlag:YES];
        }
    });
}

- (void)login:(NSString *)loginId {
    [self login:loginId withProperties:nil];
}

- (void)login:(NSString *)loginId withProperties:(NSDictionary * _Nullable )properties {
    [self loginWithKey:kHNIdentitiesLoginId loginId:loginId properties:properties];
}

- (void)loginWithKey:(NSString *)key loginId:(NSString *)loginId {
    [self loginWithKey:key loginId:loginId properties:nil];
}

- (void)loginWithKey:(NSString *)key loginId:(NSString *)loginId properties:(NSDictionary * _Nullable )properties {
    HNSignUpEventObject *object = [[HNSignUpEventObject alloc] initWithEventId:kHNEventNameSignUp];
    // 入队列前，执行动态公共属性采集 block
    [self buildDynamicSuperProperties];
    
    dispatch_async(self.serialQueue, ^{
        if (![self.identifier isValidForLogin:key value:loginId]) {
            return;
        }
        [self.identifier loginWithKey:key loginId:loginId];
        [self trackEventObject:object properties:properties];
    });
}

- (void)logout {
    dispatch_async(self.serialQueue, ^{
        BOOL isLogin = (self.loginId.length > 0);
        // logout 中会将 self.loginId 清除，因此需要在 logout 之前获取当前登录状态
        [self.identifier logout];
        if (isLogin) {
            [[NSNotificationCenter defaultCenter] postNotificationName:HN_TRACK_LOGOUT_NOTIFICATION object:nil];
        }
    });
}

- (NSString *)loginId {
    return self.identifier.loginId;
}

- (NSString *)anonymousId {
    return self.identifier.anonymousId;
}

- (NSString *)distinctId {
    return self.identifier.distinctId;
}

- (void)resetAnonymousId {
    dispatch_async(self.serialQueue, ^{
        NSString *previousAnonymousId = [self.anonymousId copy];
        [self.identifier resetAnonymousId];
        if (self.loginId || [previousAnonymousId isEqualToString:self.anonymousId]) {
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:HN_TRACK_RESETANONYMOUSID_NOTIFICATION object:nil];
    });
}

- (void)flush {
    [self flushAllEventRecords];
}

- (void)deleteAll {
    dispatch_async(self.serialQueue, ^{
        [self.eventStore deleteAllRecords];
    });
}


#pragma mark - AppLifecycle

/// 在所有模块加载完成之后调用，添加通知
/// 注意⚠️：不要随意调整通知添加顺序
- (void)addAppLifecycleObservers {
    if (self.configOptions.disableSDK) {
        return;
    }
    // app extension does not need state observer
    if ([HNApplication isAppExtension]) {
        return;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateWillChange:) name:kHNAppLifecycleStateWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateDidChange:) name:kHNAppLifecycleStateDidChangeNotification object:nil];
}

// 处理事件触发之前的逻辑
- (void)appLifecycleStateWillChange:(NSNotification *)sender {
    NSDictionary *userInfo = sender.userInfo;
    HNAppLifecycleState newState = [userInfo[kHNAppLifecycleNewStateKey] integerValue];
    HNAppLifecycleState oldState = [userInfo[kHNAppLifecycleOldStateKey] integerValue];
    
    // 热启动
    if (oldState != HNAppLifecycleStateInit && newState == HNAppLifecycleStateStart) {
        // 遍历 trackTimer
        UInt64 currentSysUpTime = [self.class getSystemUpTime];
        dispatch_async(self.serialQueue, ^{
            [self.trackTimer resumeAllEventTimers:currentSysUpTime];
        });
        return;
    }
    
    // 退出
    if (newState == HNAppLifecycleStateEnd) {
        // 清除本次启动解析的来源渠道信息
        [HNModuleManager.sharedInstance clearUtmProperties];
        // 停止计时器
        [self stopFlushTimer];
        // 遍历 trackTimer
        UInt64 currentSysUpTime = [self.class getSystemUpTime];
        dispatch_async(self.serialQueue, ^{
            [self.trackTimer pauseAllEventTimers:currentSysUpTime];
        });
        // 清除 H_referrer
        [[HNReferrerManager sharedInstance] clearReferrer];
    }
}

// 处理事件触发之后的逻辑
- (void)appLifecycleStateDidChange:(NSNotification *)sender {
    NSDictionary *userInfo = sender.userInfo;
    HNAppLifecycleState newState = [userInfo[kHNAppLifecycleNewStateKey] integerValue];
    
    // 冷（热）启动
    if (newState == HNAppLifecycleStateStart) {
        // 开启定时器
        [self startFlushTimer];
        return;
    }
    
    // 退出
    if (newState == HNAppLifecycleStateEnd) {
        
#if TARGET_OS_IOS
        UIApplication *application = [HNApplication sharedApplication];
        __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        void (^endBackgroundTask)(void) = ^() {
            [application endBackgroundTask:backgroundTaskIdentifier];
            backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        };
        backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:endBackgroundTask];
        
        dispatch_async(self.serialQueue, ^{
            [self flushAllEventRecordsWithCompletion:^{
                // 结束后台任务
                endBackgroundTask();
            }];
        });
#else
        dispatch_async(self.serialQueue, ^{
            // 上传所有的数据
            [self flushAllEventRecords];
        });
#endif
        
        return;
    }
    
    // 终止
    if (newState == HNAppLifecycleStateTerminate) {
        dispatch_sync(self.serialQueue, ^{});
    }
}

#pragma mark - HandleURL
- (BOOL)canHandleURL:(NSURL *)url {
    return [HNModuleManager.sharedInstance canHandleURL:url];
}

- (BOOL)handleSchemeUrl:(NSURL *)url {
    if (!url) {
        return NO;
    }
    
    // 退到后台时的网络状态变化不会监听，因此通过 handleSchemeUrl 唤醒 App 时主动获取网络状态
    [[HNReachability sharedInstance] startMonitoring];
    
    return [HNModuleManager.sharedInstance handleURL:url];
}

#pragma mark - Item 操作

- (void)itemSetWithType:(NSString *)itemType itemId:(NSString *)itemId properties:(nullable NSDictionary <NSString *, id> *)propertyDict {
    HNItemEventObject *object = [[HNItemEventObject alloc] initWithType:kHNEventItemSet itemType:itemType itemID:itemId];
    dispatch_async(self.serialQueue, ^{
        [self trackEventObject:object properties:propertyDict];
    });
}

- (void)itemDeleteWithType:(NSString *)itemType itemId:(NSString *)itemId {
    HNItemEventObject *object = [[HNItemEventObject alloc] initWithType:kHNEventItemDelete itemType:itemType itemID:itemId];
    dispatch_async(self.serialQueue, ^{
        [self trackEventObject:object properties:nil];
    });
}

#pragma mark - track event

- (void)profile:(NSString *)type properties:(NSDictionary *)properties {
    HNProfileEventObject *object = [[HNProfileEventObject alloc] initWithType:type];
    
    [self trackEventObject:object properties:properties];
}

- (NSDictionary *)identities {
    return self.identifier.identities;
}

- (void)bind:(NSString *)key value:(NSString *)value {
    HNBindEventObject *object = [[HNBindEventObject alloc] initWithEventId:kHNEventNameBind];
    // 入队列前，执行动态公共属性采集 block
    [self buildDynamicSuperProperties];
    dispatch_async(self.serialQueue, ^{
        if (![self.identifier isValidForBind:key value:value]) {
            return;
        }
        [self.identifier bindIdentity:key value:value];
        [self trackEventObject:object properties:nil];
    });
}

- (void)unbind:(NSString *)key value:(NSString *)value {
    HNUnbindEventObject *object = [[HNUnbindEventObject alloc] initWithEventId:kHNEventNameUnbind];
    // 入队列前，执行动态公共属性采集 block
    [self buildDynamicSuperProperties];
    dispatch_async(self.serialQueue, ^{
        if (![self.identifier isValidForUnbind:key value:value]) {
            return;
        }
        [self.identifier unbindIdentity:key value:value];
        [self trackEventObject:object properties:nil];
    });
}

- (void)track:(NSString *)event {
    [self track:event withProperties:nil];
}

- (void)track:(NSString *)event withProperties:(NSDictionary *)propertieDict {
    HNCustomEventObject *object = [[HNCustomEventObject alloc] initWithEventId:event];
    
    [self trackEventObject:object properties:propertieDict];
}

- (void)setCookie:(NSString *)cookie withEncode:(BOOL)encode {
    [_network setCookie:cookie isEncoded:encode];
}

- (NSString *)getCookieWithDecode:(BOOL)decode {
    return [_network cookieWithDecoded:decode];
}

- (BOOL)checkEventName:(NSString *)eventName {
    NSError *error = nil;
    [HNValidator validKey:eventName error:&error];
    if (!error) {
        return YES;
    }
    HNLogError(@"%@", error.localizedDescription);
    if (error.code == HNValidatorErrorInvalid || error.code == HNValidatorErrorOverflow) {
        return YES;
    }
    return NO;
}

- (nullable NSString *)trackTimerStart:(NSString *)event {
    if (![self checkEventName:event]) {
        return nil;
    }
    NSString *eventId = [_trackTimer generateEventIdByEventName:event];
    UInt64 currentSysUpTime = [self.class getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer trackTimerStart:eventId currentSysUpTime:currentSysUpTime];
    });
    return eventId;
}

- (void)trackTimerEnd:(NSString *)event {
    [self trackTimerEnd:event withProperties:nil];
}

- (void)trackTimerEnd:(NSString *)event withProperties:(NSDictionary *)propertyDict {
    // trackTimerEnd 事件需要支持新渠道匹配功能，且用户手动调用 trackTimerEnd 应归为手动埋点
    HNCustomEventObject *object = [[HNCustomEventObject alloc] initWithEventId:event];
    
    [self trackEventObject:object properties:propertyDict];
}

- (void)trackTimerPause:(NSString *)event {
    if (![self checkEventName:event]) {
        return;
    }
    UInt64 currentSysUpTime = [self.class getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer trackTimerPause:event currentSysUpTime:currentSysUpTime];
    });
}

- (void)trackTimerResume:(NSString *)event {
    if (![self checkEventName:event]) {
        return;
    }
    UInt64 currentSysUpTime = [self.class getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer trackTimerResume:event currentSysUpTime:currentSysUpTime];
    });
}

- (void)removeTimer:(NSString *)event {
    if (![self checkEventName:event]) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer trackTimerRemove:event];
    });
}

- (void)clearTrackTimer {
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer clearAllEventTimers];
    });
}

- (void)identify:(NSString *)anonymousId {
    dispatch_async(self.serialQueue, ^{
        if (![self.identifier identify:anonymousId]) {
            return;
        }
        // 其他 SDK 接收匿名 ID 修改通知，例如 AB，SF
        if (!self.loginId) {
            [[NSNotificationCenter defaultCenter] postNotificationName:HN_TRACK_IDENTIFY_NOTIFICATION object:nil];
        }
    });
}

- (NSString *)libVersion {
    return VERSION;
}

+ (NSString *)libVersion {
    return VERSION;
}

- (void)registerSuperProperties:(NSDictionary *)propertyDict {
    dispatch_async(self.serialQueue, ^{
        HNSuperPropertyPlugin *superPropertyPlugin = (HNSuperPropertyPlugin *)[[HNPropertyPluginManager sharedInstance] pluginsWithPluginClass:HNSuperPropertyPlugin.class];
        
        if (superPropertyPlugin) {
            [superPropertyPlugin registerSuperProperties:propertyDict];
        }
    });
}

- (void)registerDynamicSuperProperties:(NSDictionary<NSString *, id> *(^)(void)) dynamicSuperProperties {
    HNDynamicSuperPropertyPlugin *dynamicSuperPropertyPlugin = [HNDynamicSuperPropertyPlugin sharedDynamicSuperPropertyPlugin];
    [dynamicSuperPropertyPlugin registerDynamicSuperPropertiesBlock:dynamicSuperProperties];
}

- (void)unregisterSuperProperty:(NSString *)property {
    dispatch_async(self.serialQueue, ^{
        HNSuperPropertyPlugin *superPropertyPlugin = (HNSuperPropertyPlugin *)[[HNPropertyPluginManager sharedInstance] pluginsWithPluginClass:HNSuperPropertyPlugin.class];
        if (superPropertyPlugin) {
            [superPropertyPlugin unregisterSuperProperty:property];
        }
    });
}

- (void)clearSuperProperties {
    dispatch_async(self.serialQueue, ^{
        HNSuperPropertyPlugin *superPropertyPlugin = (HNSuperPropertyPlugin *)[[HNPropertyPluginManager sharedInstance] pluginsWithPluginClass:HNSuperPropertyPlugin.class];
        if (superPropertyPlugin) {
            [superPropertyPlugin clearSuperProperties];
        }
    });
}

- (NSDictionary *)currentSuperProperties {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    void(^block)(void) = ^{
        NSDictionary *dic = [[HNPropertyPluginManager sharedInstance] currentPropertiesForPluginClasses:@[[HNSuperPropertyPlugin class]]];
        [properties addEntriesFromDictionary:dic];
    };
    if (hinadata_is_same_queue(self.serialQueue)) {
        block();
    } else {
        dispatch_sync(self.serialQueue, block);
    }
    return properties;
}

- (void)trackEventCallback:(BOOL (^)(NSString *eventName, NSMutableDictionary<NSString *, id> *properties))callback {
    if (!callback) {
        return;
    }
    HNLogDebug(@"SDK have set trackEvent callBack");
    dispatch_async(self.serialQueue, ^{
        self.trackEventCallback = callback;
    });
}

- (void)registerLimitKeys:(NSDictionary<HNLimitKey, NSString *> *)keys {
    [HNLimitKeyManager registerLimitKeys:keys];
}

- (void)registerPropertyPlugin:(HNPropertyPlugin *)plugin {
    dispatch_async(self.serialQueue, ^{
        [HNPropertyPluginManager.sharedInstance registerPropertyPlugin:plugin];
    });
}

#pragma mark - Local caches

- (void)startFlushTimer {
    HNLogDebug(@"starting flush timer.");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer && [self.timer isValid]) {
            return;
        }
        
        if (![HNApplication isAppExtension] && self.appLifecycle.state != HNAppLifecycleStateStart) {
            return;
        }
        
        if ([HNModuleManager.sharedInstance isDisableSDK]) {
            return;
        }
        
        if (self.configOptions.flushInterval > 0) {
            double interval = self.configOptions.flushInterval > 100 ? (double)self.configOptions.flushInterval / 1000.0 : 0.1f;
            self.timer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                          target:self
                                                        selector:@selector(flush)
                                                        userInfo:nil
                                                         repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
        }
    });
}

- (void)stopFlushTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
        }
        self.timer = nil;
    });
}

- (NSString *)getLastScreenUrl {
    return [HNReferrerManager sharedInstance].referrerURL;
}

- (void)clearReferrerWhenAppEnd {
    [HNReferrerManager sharedInstance].isClearReferrer = YES;
}

- (NSDictionary *)getLastScreenTrackProperties {
    return [HNReferrerManager sharedInstance].referrerProperties;
}

- (HinaDataDebugMode)debugMode {
    return self.configOptions.debugMode;
}

#pragma mark - HinaData  Analytics

- (void)profilePushKey:(NSString *)pushTypeKey pushId:(NSString *)pushId {
    if ([pushTypeKey isKindOfClass:NSString.class] && pushTypeKey.length && [pushId isKindOfClass:NSString.class] && pushId.length) {
        NSString * keyOfPushId = [NSString stringWithFormat:@"sa_%@", pushTypeKey];
        NSString * valueOfPushId = [[HNStoreManager sharedInstance] stringForKey:keyOfPushId];
        NSString * newValueOfPushId = [NSString stringWithFormat:@"%@_%@", self.distinctId, pushId];
        if (![valueOfPushId isEqualToString:newValueOfPushId]) {
            [self set:@{pushTypeKey:pushId}];
            [[HNStoreManager sharedInstance] setObject:newValueOfPushId forKey:keyOfPushId];
        }
    }
}

- (void)profileUnsetPushKey:(NSString *)pushTypeKey {
    NSAssert(([pushTypeKey isKindOfClass:[NSString class]] && pushTypeKey.length), @"pushTypeKey should be a non-empty string object!!!❌❌❌");
    NSString *localKey = [NSString stringWithFormat:@"sa_%@", pushTypeKey];
    NSString *localValue = [[HNStoreManager sharedInstance] stringForKey:localKey];
    if ([localValue hasPrefix:self.distinctId]) {
        [self unset:pushTypeKey];
        [[HNStoreManager sharedInstance] removeObjectForKey:localKey];
    }
}

- (void)set:(NSDictionary *)profileDict {
    if (profileDict) {
        [self profile:kHNProfileSet properties:profileDict];
    }
}

- (void)setOnce:(NSDictionary *)profileDict {
    if (profileDict) {
        [self profile:kHNProfileSetOnce properties:profileDict];
    }
}

- (void)set:(NSString *) profile to:(id)content {
    if (profile && content) {
        [self profile:kHNProfileSet properties:@{profile: content}];
    }
}

- (void)setOnce:(NSString *) profile to:(id)content {
    if (profile && content) {
        [self profile:kHNProfileSetOnce properties:@{profile: content}];
    }
}

- (void)unset:(NSString *) profile {
    if (profile) {
        [self profile:kHNProfileUnset properties:@{profile: @""}];
    }
}

- (void)increment:(NSString *)profile by:(NSNumber *)amount {
    if (profile && amount) {
        HNProfileIncrementEventObject *object = [[HNProfileIncrementEventObject alloc] initWithType:kHNProfileIncrement];
        
        [self trackEventObject:object properties:@{profile: amount}];
    }
}

- (void)increment:(NSDictionary *)profileDict {
    if (profileDict) {
        HNProfileIncrementEventObject *object = [[HNProfileIncrementEventObject alloc] initWithType:kHNProfileIncrement];
        
        [self trackEventObject:object properties:profileDict];
    }
}

- (void)append:(NSString *)profile by:(NSObject<NSFastEnumeration> *)content {
    if (profile && content) {
        if ([content isKindOfClass:[NSSet class]] || [content isKindOfClass:[NSArray class]]) {
            HNProfileAppendEventObject *object = [[HNProfileAppendEventObject alloc] initWithType:kHNProfileAppend];
            
            [self trackEventObject:object properties:@{profile: content}];
        }
    }
}

- (void)deleteUser {
    [self profile:kHNProfileDelete properties:@{}];
}

- (void)enableLog:(BOOL)enableLog {
    self.configOptions.enableLog = enableLog;
    [HNLog sharedLog].enableLog = enableLog;
    if (!enableLog) {
        return;
    }
    [self enableLoggers];
}

- (void)clearKeychainData {
    [HNKeyChainItemWrapper deletePasswordWithAccount:kHNUdidAccount service:kHNService];
}

#pragma mark - setup Flow

- (void)trackEventObject:(HNBaseEventObject *)object properties:(NSDictionary *)properties {
    if (object.isSignUp) {
        [[NSNotificationCenter defaultCenter] postNotificationName:HN_TRACK_LOGIN_NOTIFICATION object:nil];
    }
    NSString *eventName = object.event;
    if (!object.hybridH5 && eventName) {
        object.isInstantEvent = [self.configOptions.instantEvents containsObject:eventName];
    }
    HNFlowData *input = [[HNFlowData alloc] init];
    input.eventObject = object;
    input.identifier = self.identifier;
    input.properties = [properties hinadata_deepCopy];
    [HNFlowManager.sharedInstance startWithFlowID:kHNTrackFlowId input:input completion:nil];
}

- (void)flushAllEventRecords {
    [self flushAllEventRecordsWithCompletion:nil];
}

- (void)flushAllEventRecordsWithCompletion:(void(^)(void))completion {
    NSString *cookie = [self getCookieWithDecode:NO];
    HNFlowData *instantEventFlushInput = [[HNFlowData alloc] init];
    instantEventFlushInput.cookie = cookie;
    instantEventFlushInput.isInstantEvent = YES;
    [HNFlowManager.sharedInstance startWithFlowID:kHNFlushFlowId input:instantEventFlushInput completion:^(HNFlowData * _Nonnull output) {
        HNFlowData *normalFlushInput = [[HNFlowData alloc] init];
        normalFlushInput.cookie = cookie;
        [HNFlowManager.sharedInstance startWithFlowID:kHNFlushFlowId input:normalFlushInput completion:^(HNFlowData * _Nonnull output) {
            if (completion) {
                completion();
            }
        }];
    }];
}

- (void)buildDynamicSuperProperties {
    HNDynamicSuperPropertyPlugin *dynamicSuperPropertyPlugin = [HNDynamicSuperPropertyPlugin sharedDynamicSuperPropertyPlugin];
    [dynamicSuperPropertyPlugin buildDynamicSuperProperties];
}

#pragma mark - RemoteConfig

/// 远程控制通知回调需要在所有其他通知之前调用
/// 注意⚠️：不要随意调整通知添加顺序
- (void)addRemoteConfigObservers {
    if (self.configOptions.disableSDK) {
        return;
    }
#if TARGET_OS_IOS
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteConfigManagerModelChanged:) name:HN_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:nil];
#endif
}

- (void)remoteConfigManagerModelChanged:(NSNotification *)sender {
    @try {
        BOOL isDisableDebugMode = [[sender.object valueForKey:@"disableDebugMode"] boolValue];
        if (isDisableDebugMode) {
            self.configOptions.debugMode = HinaDataDebugOff;
        }

        BOOL isDisableSDK = [[sender.object valueForKey:@"disableSDK"] boolValue];
        if (isDisableSDK) {
            [self stopFlushTimer];
            [self removeWebViewUserAgent];
            // 停止采集数据之后 flush 本地数据
            [self flush];
        } else {
            [self startFlushTimer];
            [self appendWebViewUserAgent];
        }
    } @catch(NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
}

- (void)removeWebViewUserAgent {
    if (!self.addWebViewUserAgent) {
        // 没有开启老版打通
        return;
    }
    
    NSString *currentUserAgent = [HNCommonUtility currentUserAgent];
    if (![currentUserAgent containsString:self.addWebViewUserAgent]) {
        return;
    }
    
    NSString *newUserAgent = [currentUserAgent stringByReplacingOccurrencesOfString:self.addWebViewUserAgent withString:@""];
    self.userAgent = newUserAgent;
    [HNCommonUtility saveUserAgent:self.userAgent];
}

- (void)appendWebViewUserAgent {
    if (!self.addWebViewUserAgent) {
        // 没有开启老版打通
        return;
    }

    if ([HNModuleManager.sharedInstance isDisableSDK]) {
        return;
    }

    NSString *currentUserAgent = [HNCommonUtility currentUserAgent];
    if ([currentUserAgent containsString:self.addWebViewUserAgent]) {
        return;
    }
    
    NSMutableString *newUserAgent = [NSMutableString string];
    if (currentUserAgent) {
        [newUserAgent appendString:currentUserAgent];
    }
    [newUserAgent appendString:self.addWebViewUserAgent];
    self.userAgent = newUserAgent;
    [HNCommonUtility saveUserAgent:self.userAgent];
}

- (void)trackFromH5WithEvent:(NSString *)eventInfo {
    [self trackFromH5WithEvent:eventInfo enableVerify:NO];
}

- (void)trackFromH5WithEvent:(NSString *)eventInfo enableVerify:(BOOL)enableVerify {
    if (!eventInfo) {
        return;
    }
    NSMutableDictionary *eventDict = [HNJSONUtil JSONObjectWithString:eventInfo options:NSJSONReadingMutableContainers];
    if (!eventDict) {
        return;
    }

    if (enableVerify) {
        NSString *serverUrl = eventDict[@"server_url"];
        if (![self.network isSameProjectWithURLString:serverUrl]) {
            HNLogError(@"Server_url verified faild, Web event lost! Web server_url = '%@'", serverUrl);
            return;
        }
    }

    HNBaseEventObject *object = [HNEventObjectFactory eventObjectWithH5Event:eventDict];
    dispatch_async(self.serialQueue, ^{

        NSString *visualProperties = eventDict[kHNEventProperties][kHNAppVisualProperties];
        // 是否包含自定义属性配置，根据配置采集 App 属性内容
        if (!visualProperties || ![object.event isEqualToString:kHNEventNameWebClick]) {
            [self trackFromH5WithEventObject:object properties:nil];
            return;
        }

        NSData *data = [[NSData alloc] initWithBase64EncodedString:visualProperties options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSArray <NSDictionary *> *visualPropertyConfigs = [HNJSONUtil JSONObjectWithData:data];

        // 查询 App 自定义属性值
        [HNModuleManager.sharedInstance queryVisualPropertiesWithConfigs:visualPropertyConfigs completionHandler:^(NSDictionary *_Nullable properties) {

            // 切换到 serialQueue 执行
            dispatch_async(self.serialQueue, ^{
                [self trackFromH5WithEventObject:object properties:properties];
            });
        }];
    });
}

- (void)trackFromH5WithEventObject:(HNBaseEventObject *)object properties:(NSDictionary *)properties {
    [self trackEventObject:object properties:properties];
}

@end

#pragma mark - Deprecated
@implementation HinaDataSDK (Deprecated)

// 广告 SDK 调用，暂时保留
- (void)asyncTrackEventObject:(HNBaseEventObject *)object properties:(NSDictionary *)properties {
    [self trackEventObject:object properties:properties];
}

- (NSInteger)flushInterval {
    @synchronized(self) {
        return self.configOptions.flushInterval;
    }
}

- (void)setFlushInterval:(NSInteger)interval {
    @synchronized(self) {
        self.configOptions.flushInterval = interval;
    }
    [self flush];
    [self stopFlushTimer];
    [self startFlushTimer];
}

- (NSInteger)flushBulkSize {
    @synchronized(self) {
        return self.configOptions.flushBulkSize;
    }
}

- (void)setFlushBulkSize:(NSInteger)bulkSize {
    @synchronized(self) {
        self.configOptions.flushBulkSize = bulkSize;
    }
}

- (void)setMaxCacheSize:(NSInteger)maxCacheSize {
    @synchronized(self) {
        self.configOptions.maxCacheSize = maxCacheSize;
    };
}

- (NSInteger)maxCacheSize {
    @synchronized(self) {
        return self.configOptions.maxCacheSize;
    };
}

- (void)setFlushNetworkPolicy:(HinaDataNetworkType)networkType {
    @synchronized (self) {
        self.configOptions.flushNetworkPolicy = networkType;
    }
}

- (void)setDebugMode:(HinaDataDebugMode)debugMode {
    self.configOptions.debugMode = debugMode;
}

- (void)trackTimer:(NSString *)event {
    [self trackTimer:event withTimeUnit:HinaDataTimeUnitMilliseconds];
}

- (void)trackTimer:(NSString *)event withTimeUnit:(HinaDataTimeUnit)timeUnit {
    UInt64 currentSysUpTime = [self.class getSystemUpTime];
    dispatch_async(self.serialQueue, ^{
        [self.trackTimer trackTimerStart:event timeUnit:timeUnit currentSysUpTime:currentSysUpTime];
    });
}

@end
