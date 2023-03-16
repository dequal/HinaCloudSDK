//
// HNDeepLinkManager.m
// HinaDataSDK
//
// Created by hina on 2022/1/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDeepLinkManager.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"
#import "HNURLUtils.h"
#import "HNStoreManager.h"
#import "HNLog.h"
#import "HNIdentifier.h"
#import "HNJSONUtil.h"
#import "HNNetwork.h"
#import "HNModuleManager.h"
#import "HNUserAgent.h"
#import "HinaDataSDK+DeepLink.h"
#import "HNApplication.h"
#import "HNDeepLinkConstants.h"
#import "HNDeepLinkProcessor.h"
#import "HNDeferredDeepLinkProcessor.h"
#import "HNDeepLinkEventProcessor.h"
#import "HNFirstDayPropertyPlugin.h"
#import "HNPropertyPluginManager.h"
#import "HNLatestUtmPropertyPlugin.h"
#import "HNDeviceWhiteList.h"


@interface HNDeepLinkManager () <HNDeepLinkProcessorDelegate>

/// 本次唤起时的渠道信息
@property (atomic, strong) NSMutableDictionary *channels;
/// 最后一次唤起时的渠道信息
@property (atomic, copy) NSDictionary *latestChannels;
/// 自定义渠道字段名
@property (nonatomic, copy) NSSet *customChannelKeys;
/// 本次冷启动时的 DeepLinkURL
@property (nonatomic, strong) NSURL *deepLinkURL;

@property (nonatomic, strong) HNDeviceWhiteList *whiteList;

@end

@implementation HNDeepLinkManager

typedef NS_ENUM(NSInteger, HNDeferredDeepLinkStatus) {
    HNDeferredDeepLinkStatusInit = 0,
    HNDeferredDeepLinkStatusEnable,
    HNDeferredDeepLinkStatusDisable
};

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNDeepLinkManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNDeepLinkManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        //  注册渠道相关属性插件，LatestUtm
        HNLatestUtmPropertyPlugin *latestUtmPropertyPlugin = [[HNLatestUtmPropertyPlugin alloc] init];
        [HinaDataSDK.sharedInstance registerPropertyPlugin:latestUtmPropertyPlugin];

        _channels = [NSMutableDictionary dictionary];
        NSInteger status = [self deferredDeepLinkStatus];

        HNFirstDayPropertyPlugin *firstDayPlugin = [[HNFirstDayPropertyPlugin alloc] init];
        BOOL isFirstDay = [firstDayPlugin isFirstDay];
        // isFirstDay 是为了避免用户版本升级场景下，不需要触发 Deferred DeepLink 逻辑的问题
        if (isFirstDay && status == HNDeferredDeepLinkStatusInit) {
            [self enableDeferredDeepLink];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateDidChange:) name:kHNAppLifecycleStateDidChangeNotification object:nil];
        } else {
            [self disableDeferredDeepLink];
        }
        _whiteList = [[HNDeviceWhiteList alloc] init];
    }
    return self;
}

- (void)appLifecycleStateDidChange:(NSNotification *)sender {
    HNAppLifecycleState newState = [sender.userInfo[kHNAppLifecycleNewStateKey] integerValue];
    if (newState == HNAppLifecycleStateEnd) {
        [self disableDeferredDeepLink];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kHNAppLifecycleStateDidChangeNotification object:nil];
    }
}

- (HNDeferredDeepLinkStatus)deferredDeepLinkStatus {
    return [[HNStoreManager sharedInstance] integerForKey:kHNDeferredDeepLinkStatus];
}

- (void)enableDeferredDeepLink {
    [[HNStoreManager sharedInstance] setInteger:HNDeferredDeepLinkStatusEnable forKey:kHNDeferredDeepLinkStatus];
}

- (void)disableDeferredDeepLink {
    [[HNStoreManager sharedInstance] setInteger:HNDeferredDeepLinkStatusDisable forKey:kHNDeferredDeepLinkStatus];
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    if ([HNApplication isAppExtension]) {
        configOptions.enableDeepLink = NO;
    }
    _configOptions = configOptions;

    [self filterValidSourceChannelKeys:configOptions.sourceChannels];
    [self unarchiveLatestChannels:configOptions.enableSaveDeepLinkInfo];
    [self handleLaunchOptions:configOptions.launchOptions];
    [self acquireColdLaunchDeepLinkInfo];
    self.enable = configOptions.enableDeepLink;
}

- (void)filterValidSourceChannelKeys:(NSArray *)sourceChannels {
    NSSet *reservedPropertyName = hinadata_reserved_properties();
    NSMutableSet *set = [[NSMutableSet alloc] init];
    // 将用户自定义属性中与 SDK 保留字段相同的字段过滤掉
    for (NSString *name in sourceChannels) {
        if (![reservedPropertyName containsObject:name]) {
            [set addObject:name];
        } else {
            // 这里只做 LOG 提醒
            HNLogError(@"deepLink source channel property [%@] is invalid!!!", name);
        }
    }
    self.customChannelKeys = set;
}

- (void)unarchiveLatestChannels:(BOOL)enableSave {
    if (!enableSave) {
        [[HNStoreManager sharedInstance] removeObjectForKey:kHNDeepLinkLatestChannelsFileName];
        return;
    }
    NSDictionary *local = [[HNStoreManager sharedInstance] objectForKey:kHNDeepLinkLatestChannelsFileName];
    if (!local) {
        return;
    }
    NSArray *array = @[@{@"names":hinadata_preset_channel_keys(), @"prefix":@"H_latest"},
                       @{@"names":self.customChannelKeys, @"prefix":@"_latest"}];
    NSMutableDictionary *latest = [NSMutableDictionary dictionary];
    for (NSDictionary *obj in array) {
        for (NSString *name in obj[@"names"]) {
            // 升级版本时 sourceChannels 可能会发生变化，过滤掉本次 sourceChannels 中已不包含的字段
            NSString *latestKey = [NSString stringWithFormat:@"%@_%@", obj[@"prefix"], name];
            NSString *value = [local[latestKey] stringByRemovingPercentEncoding];
            if (value.length > 0) {
                latest[latestKey] = value;
            }
        }
    }
    self.latestChannels = latest;
}

/// 开启本地保存 DeepLinkInfo 开关时，每次 DeepLink 唤起解析后都需要更新本地文件中数据
- (void)archiveLatestChannels:(NSDictionary *)dictionary {
    if (!_configOptions.enableSaveDeepLinkInfo) {
        return;
    }
    [[HNStoreManager sharedInstance] setObject:dictionary forKey:kHNDeepLinkLatestChannelsFileName];
}

// 记录冷启动的 DeepLink URL
- (void)handleLaunchOptions:(id)options {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000)
    if (@available(iOS 13.0, *)) {
        // 兼容 SceneDelegate 场景
        if ([options isKindOfClass:UISceneConnectionOptions.class]) {
            UISceneConnectionOptions *sceneOptions = (UISceneConnectionOptions *)options;
            NSUserActivity *userActivity = sceneOptions.userActivities.allObjects.firstObject;
            UIOpenURLContext *urlContext = sceneOptions.URLContexts.allObjects.firstObject;
            _deepLinkURL = urlContext.URL ? urlContext.URL : userActivity.webpageURL;
            return;
        }
    }
#endif
    if (![options isKindOfClass:NSDictionary.class]) {
        return;
    }
    NSDictionary *launchOptions = (NSDictionary *)options;
    if ([launchOptions.allKeys containsObject:UIApplicationLaunchOptionsURLKey]) {
        //通过 SchemeLink 唤起 App
        _deepLinkURL = launchOptions[UIApplicationLaunchOptionsURLKey];
    }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
    else if (@available(iOS 8.0, *)) {
        NSDictionary *userActivityDictionary = launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey];
        NSString *type = userActivityDictionary[UIApplicationLaunchOptionsUserActivityTypeKey];
        if ([type isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            //通过 UniversalLink 唤起 App
            NSUserActivity *userActivity = userActivityDictionary[@"UIApplicationLaunchOptionsUserActivityKey"];
            _deepLinkURL = userActivity.webpageURL;
        }
    }
#endif
}

// 冷启动时 H_AppStart 中需要添加 H_deeplink_url 信息，且要保证 H_AppDeeplinkLaunch 早于 H_AppStart。
// 因此这里需要提前处理 DeepLink 逻辑
- (void)acquireColdLaunchDeepLinkInfo {
    // 避免方法被多次调用
    static dispatch_once_t deepLinkToken;
    dispatch_once(&deepLinkToken, ^{
        if (![self canHandleURL:_deepLinkURL]) {
            return;
        }

        [self disableDeferredDeepLink];
        [self handleDeepLinkURL:_deepLinkURL];
    });
}

#pragma mark - channel properties
/// H_latest_utm_* 属性，当本次启动是通过 DeepLink 唤起时所有 event 事件都会新增这些属性
- (nullable NSDictionary *)latestUtmProperties {
    return [self.latestChannels copy];
}

/// H_utm_* 属性，当通过 DeepLink 唤起 App 时 只针对  H_AppStart 事件和第一个 H_AppViewScreen 事件会新增这些属性
- (NSDictionary *)utmProperties {
    return [self.channels copy];
}

/// 在固定场景下需要清除 utm_* 属性
// 通过 DeepLink 唤起 App 时需要清除上次的 utm 属性
// 通过 DeepLink 唤起 App 并触发第一个页面浏览时需要清除本次的 utm 属性
// 退出 App 时需要清除本次的 utms 属性
- (void)clearUtmProperties {
    [self.channels removeAllObjects];
}

/// 只有通过 DeepLink 唤起 App 时需要清除 latest utms
- (void)clearLatestUtmProperties {
    self.latestChannels = nil;
}

/// 清空上一次 DeepLink 唤起时的信息，并保存本次唤起的 URL
- (void)clearLastDeepLinkInfo {
    [self clearUtmProperties];
    [self clearLatestUtmProperties];
    // 删除本地保存的 DeepLink 信息
    [self archiveLatestChannels:nil];
}

#pragma mark - Handle DeepLink
- (BOOL)canHandleURL:(NSURL *)url {
    if (![url isKindOfClass:NSURL.class]) {
        return NO;
    }
    if ([self.whiteList canHandleURL:url]) {
        return YES;
    }
    HNDeepLinkProcessor *processor = [HNDeepLinkProcessorFactory processorFromURL:url customChannelKeys:self.customChannelKeys];
    return processor.canWakeUp;
}

- (BOOL)handleURL:(NSURL *)url {
    if ([self.whiteList canHandleURL:url]) {
        return [self.whiteList handleURL:url];
    }
    // 当 url 和 _deepLinkURL 相同时，则表示本次触发是冷启动触发,已通过 acquireColdLaunchDeepLinkInfo 方法处理，这里不需要重复处理
    NSString *absoluteString = _deepLinkURL.absoluteString;
    _deepLinkURL = nil;
    if ([url.absoluteString isEqualToString:absoluteString]) {
        return NO;
    }
    return [self handleDeepLinkURL:url];
}

- (BOOL)handleDeepLinkURL:(NSURL *)url {
    if (!url) {
        return NO;
    }

    [self clearLastDeepLinkInfo];

    // 在 channels 中保存本次唤起的 DeepLink URL 添加到指定事件中
    self.channels[kHNEventPropertyDeepLinkURL] = url.absoluteString;

    HNDeepLinkProcessor *processor = [HNDeepLinkProcessorFactory processorFromURL:url customChannelKeys:self.customChannelKeys];
    processor.delegate = self;
    [processor startWithProperties:nil];
    return processor.canWakeUp;
}

#pragma mark - Public Methods
- (void)trackDeepLinkLaunchWithURL:(NSString *)url {
    if (url && ![url isKindOfClass:NSString.class]) {
        HNLogError(@"deeplink url must be NSString. got: %@ %@", url.class, url);
        return;
    }
    HNDeepLinkEventProcessor *processor = [[HNDeepLinkEventProcessor alloc] init];
    [processor startWithProperties:nil];
}

- (void)requestDeferredDeepLink:(NSDictionary *)properties {
    // 当不是首次安装 App 时，则不需要再触发 Deferred DeepLink 请求
    if ([self deferredDeepLinkStatus] == HNDeferredDeepLinkStatusDisable) {
        return;
    }

    [self disableDeferredDeepLink];

    HNDeferredDeepLinkProcessor *processor = [[HNDeferredDeepLinkProcessor alloc] init];
    processor.delegate = self;
    processor.customChannelKeys = self.customChannelKeys;
    [processor startWithProperties:properties];
}

#pragma mark - processor delegate
- (HNDeepLinkCompletion)sendChannels:(NSDictionary *)channels latestChannels:(NSDictionary *)latestChannels isDeferredDeepLink:(BOOL)isDeferredDeepLink {
    // 合并本次唤起的渠道信息，channels 中已保存 DeepLink URL，所以不能直接覆盖
    [self.channels addEntriesFromDictionary:channels];

    // 覆盖本次唤起的渠道信息，只包含 H_latest_utm_* 和 _latest_* 属性
    self.latestChannels = latestChannels;
    [self archiveLatestChannels:latestChannels];

    if (self.completion) {
        return self.completion;
    }

    // 1. 当是 DeferredDeepLink 时，不兼容老版本 completion，不做回调处理
    // 2. 当老版本 completion 也不存在时，不做回调处理
    if (isDeferredDeepLink || !self.oldCompletion) {
        return nil;
    }

    return self.oldCompletion;
}

@end
