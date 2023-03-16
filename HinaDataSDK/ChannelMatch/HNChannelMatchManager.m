//
// HNChannelMatchManager.m
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNChannelMatchManager.h"
#import "HNConstants+Private.h"
#import "HNIdentifier.h"
#import "HinaDataSDK+Private.h"
#import "HNValidator.h"
#import "HNAlertController.h"
#import "HNURLUtils.h"
#import "HNReachability.h"
#import "HNLog.h"
#import "HNStoreManager.h"
#import "HNJSONUtil.h"
#import "HinaDataSDK+HNChannelMatch.h"
#import "HNApplication.h"
#import "HNProfileEventObject.h"
#import "HNPropertyPluginManager.h"
#import "HNChannelInfoPropertyPlugin.h"

NSString * const kHNChannelDebugFlagKey = @"com.hinadata.channeldebug.flag";
NSString * const kHNChannelDebugInstallEventName = @"H_ChannelDebugInstall";
NSString * const kHNEventPropertyChannelDeviceInfo = @"H_channel_device_info";
NSString * const kHNEventPropertyUserAgent = @"H_user_agent";
NSString * const kHNEventPropertyChannelCallbackEvent = @"H_is_channel_callback_event";

static NSString * const kHNHasTrackInstallation = @"HasTrackInstallation";
static NSString * const kHNHasTrackInstallationDisableCallback = @"HasTrackInstallationWithDisableCallback";

@interface HNChannelMatchManager ()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;
@property (nonatomic, strong) NSMutableSet<NSString *> *trackChannelEventNames;

@end

@implementation HNChannelMatchManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNChannelMatchManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNChannelMatchManager alloc] init];
    });
    return manager;
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    if ([HNApplication isAppExtension]) {
        configOptions.enableChannelMatch = NO;
    }
    _configOptions = configOptions;
    self.enable = configOptions.enableChannelMatch;

    // 注册渠道相关属性插件 Channel
    HNChannelInfoPropertyPlugin *channelInfoPropertyPlugin = [[HNChannelInfoPropertyPlugin alloc] init];
    [HinaDataSDK.sharedInstance registerPropertyPlugin:channelInfoPropertyPlugin];
}

#pragma mark -

- (NSMutableSet<NSString *> *)trackChannelEventNames {
    if (!_trackChannelEventNames) {
        _trackChannelEventNames = [[NSMutableSet alloc] init];
        NSSet *trackChannelEvents = (NSSet *)[[HNStoreManager sharedInstance] objectForKey:kHNEventPropertyChannelDeviceInfo];
        if (trackChannelEvents) {
            [_trackChannelEventNames unionSet:trackChannelEvents];
        }
    }
    return _trackChannelEventNames;
}

#pragma mark - indicator view
- (void)showIndicator {
    _window = [self alertWindow];
    _window.windowLevel = UIWindowLevelAlert + 1;
    UIViewController *controller = [[HNAlertController alloc] init];
    _window.rootViewController = controller;
    _window.hidden = NO;
    _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _indicator.center = CGPointMake(_window.center.x, _window.center.y);
    [_window.rootViewController.view addSubview:_indicator];
    [_indicator startAnimating];
}

- (void)hideIndicator {
    [_indicator stopAnimating];
    _indicator = nil;
    _window = nil;
}

- (UIWindow *)alertWindow {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000)
    if (@available(iOS 13.0, *)) {
        __block UIWindowScene *scene = nil;
        [UIApplication.sharedApplication.connectedScenes.allObjects enumerateObjectsUsingBlock:^(UIScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIWindowScene class]]) {
                scene = (UIWindowScene *)obj;
                *stop = YES;
            }
        }];
        if (scene) {
            return [[UIWindow alloc] initWithWindowScene:scene];
        }
    }
#endif
    return [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
}

#pragma mark - 渠道联调诊断标记
/// 客户是否触发过激活事件
- (BOOL)isAppInstalled {
    HNStoreManager *manager = [HNStoreManager sharedInstance];
    return [manager boolForKey:kHNHasTrackInstallationDisableCallback] || [manager boolForKey:kHNHasTrackInstallation];
}

/// 客户可以使用渠道联调诊断功能
- (BOOL)isValidForChannelDebug {
    if (![self isAppInstalled]) {
        // 当未触发过激活事件时，可以使用联调诊断功能
        return YES;
    }
    return [[HNStoreManager sharedInstance] boolForKey:kHNChannelDebugFlagKey];
}

/// 当前获取到的设备 ID 为有效值
- (BOOL)isValidOfDeviceInfo {
    return [HNIdentifier idfa].length > 0;
}

- (BOOL)isTrackedAppInstallWithDisableCallback:(BOOL)disableCallback {
    NSString *key = disableCallback ? kHNHasTrackInstallationDisableCallback : kHNHasTrackInstallation;
    return [[HNStoreManager sharedInstance] boolForKey:key];
}

- (void)setTrackedAppInstallWithDisableCallback:(BOOL)disableCallback {
    HNStoreManager *manager = [HNStoreManager sharedInstance];
    NSString *userDefaultsKey = disableCallback ? kHNHasTrackInstallationDisableCallback : kHNHasTrackInstallation;

    // 记录激活事件是否获取到了有效的设备 ID 信息，设备 ID 信息有效时后续可以使用联调诊断功能
    [manager setBool:[self isValidOfDeviceInfo] forKey:kHNChannelDebugFlagKey];

    // 激活事件 - 根据 disableCallback 记录是否触发过激活事件
    [manager setBool:YES forKey:userDefaultsKey];
}

#pragma mark - 激活事件
- (void)trackAppInstall:(NSString *)event properties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback{
    // 采集激活事件
    HNPresetEventObject *eventObject = [[HNPresetEventObject alloc] initWithEventId:event];
    NSDictionary *eventProps = [self eventProperties:properties disableCallback:disableCallback];
    [HinaDataSDK.sharedInstance trackEventObject:eventObject properties:eventProps];

    // 设置用户属性
    HNProfileEventObject *profileObject = [[HNProfileEventObject alloc] initWithType:kHNProfileSetOnce];
    NSDictionary *profileProps = [self profileProperties:properties];
    [HinaDataSDK.sharedInstance trackEventObject:profileObject properties:profileProps];
}

- (NSDictionary *)eventProperties:(NSDictionary *)properties disableCallback:(BOOL)disableCallback {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if ([HNValidator isValidDictionary:properties]) {
        [result addEntriesFromDictionary:properties];
    }

    if (disableCallback) {
        result[kHNEventPropertyInstallDisableCallback] = @YES;
    }

    if ([result[kHNEventPropertyUserAgent] length] == 0) {
        result[kHNEventPropertyUserAgent] = [self simulateUserAgent];
    }

    result[kHNEventPropertyInstallSource] = [self appInstallSource];

    return result;
}

- (NSDictionary *)profileProperties:(NSDictionary *)properties {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    if ([HNValidator isValidDictionary:properties]) {
        [result addEntriesFromDictionary:properties];
    }

    if ([result[kHNEventPropertyUserAgent] length] == 0) {
        result[kHNEventPropertyUserAgent] = [self simulateUserAgent];
    }

    result[kHNEventPropertyInstallSource] = [self appInstallSource];

    // 用户属性中不需要添加 H_ios_install_disable_callback，这里主动移除掉
    // (也会移除自定义属性中的 H_ios_install_disable_callback, 和原有逻辑保持一致)
    [result removeObjectForKey:kHNEventPropertyInstallDisableCallback];

    [result setValue:[NSDate date] forKey:kHNEventPropertyAppInstallFirstVisitTime];

    return result;
}

- (NSString *)appInstallSource {
    NSMutableDictionary *sources = [NSMutableDictionary dictionary];
    sources[@"idfa"] = [HNIdentifier idfa];
    sources[@"idfv"] = [HNIdentifier idfv];
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *key in sources.allKeys) {
        [result addObject:[NSString stringWithFormat:@"%@=%@", key, sources[key]]];
    }
    return [result componentsJoinedByString:@"##"];
}

#pragma mark - 附加渠道信息
- (void)trackChannelWithEventObject:(HNBaseEventObject *)obj properties:(nullable NSDictionary *)propertyDict {
    if (self.configOptions.enableAutoAddChannelCallbackEvent) {
        return [HinaDataSDK.sharedInstance trackEventObject:obj properties:propertyDict];
    }
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:propertyDict];
    // ua
    if ([propertyDict[kHNEventPropertyUserAgent] length] == 0) {
        properties[kHNEventPropertyUserAgent] = [self simulateUserAgent];
    }
    // idfa
    NSString *idfa = [HNIdentifier idfa];
    if (idfa) {
        [properties setValue:[NSString stringWithFormat:@"idfa=%@", idfa] forKey:kHNEventPropertyChannelDeviceInfo];
    } else {
        [properties setValue:@"" forKey:kHNEventPropertyChannelDeviceInfo];
    }
    // callback
    [properties addEntriesFromDictionary:[self channelPropertiesWithEvent:obj.event]];

    [HinaDataSDK.sharedInstance trackEventObject:obj properties:properties];
}

- (NSDictionary *)channelPropertiesWithEvent:(NSString *)event {
    BOOL isNotContains = ![self.trackChannelEventNames containsObject:event];
    if (isNotContains && event) {
        [self.trackChannelEventNames addObject:event];
        [self archiveTrackChannelEventNames];
    }
    return @{kHNEventPropertyChannelCallbackEvent : @(isNotContains)};
}

- (void)archiveTrackChannelEventNames {
    [[HNStoreManager sharedInstance] setObject:self.trackChannelEventNames forKey:kHNEventPropertyChannelDeviceInfo];
}

- (NSDictionary *)channelInfoWithEvent:(NSString *)event {
    if (self.configOptions.enableAutoAddChannelCallbackEvent) {
        NSMutableDictionary *channelInfo = [NSMutableDictionary dictionaryWithDictionary:[self channelPropertiesWithEvent:event]];
        channelInfo[kHNEventPropertyChannelDeviceInfo] = @"1";
        return channelInfo;
    }
    return nil;
}

- (NSString *)simulateUserAgent {
    NSString *version = [UIDevice.currentDevice.systemVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString *model = UIDevice.currentDevice.model;
    return [NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU OS %@ like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile", model, version];
}

#pragma mark - handle URL
- (BOOL)canHandleURL:(NSURL *)url {
    NSDictionary *queryItems = [HNURLUtils queryItemsWithURL:url];
    NSString *monitorId = queryItems[@"monitor_id"];
    return [url.host isEqualToString:@"channeldebug"] && monitorId.length;
}

- (BOOL)handleURL:(NSURL *)url {
    if (![self canHandleURL:url]) {
        return NO;
    }

    HNNetwork *network = [HinaDataSDK sharedInstance].network;
    if (!network.serverURL.absoluteString.length) {
        [self showErrorMessage:HNLocalizedString(@"HNChannelServerURLError")];
        return NO;
    }
    NSString *project = [HNURLUtils queryItemsWithURLString:url.absoluteString][@"project_name"] ?: @"default";
    BOOL isEqualProject = [network.project isEqualToString:project];
    if (!isEqualProject) {
        [self showErrorMessage:HNLocalizedString(@"HNChannelProjectError")];
        return NO;
    }
    // 如果是重连二维码功能，直接进入重连二维码流程
    if ([self isRelinkURL:url]) {
        [self showRelinkAlertWithURL:url];
        return YES;
    }
    // 展示渠道联调诊断询问弹窗
    [self showAuthorizationAlertWithURL:url];
    return YES;
}

#pragma mark - 重连二维码
- (BOOL)isRelinkURL:(NSURL *)url {
    NSDictionary *queryItems = [HNURLUtils queryItemsWithURL:url];
    return [queryItems[@"is_relink"] boolValue];
}

- (void)showRelinkAlertWithURL:(NSURL *)url {
    NSDictionary *queryItems = [HNURLUtils queryItemsWithURL:url];
    NSString *deviceId = [queryItems[@"device_code"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    // 重连二维码对应的设备信息
    NSMutableSet *deviceIdSet = [NSMutableSet setWithArray:[deviceId componentsSeparatedByString:@"##"]];
    // 当前设备的设备信息
    NSSet *installSourceSet = [NSSet setWithArray:[[self appInstallSource] componentsSeparatedByString:@"##"]];
    [deviceIdSet intersectSet:installSourceSet];
    // 取交集，当交集不为空时，表示设备一致
    if (deviceIdSet.count > 0) {
        [self showChannelDebugInstall];
    } else {
        [self showErrorMessage:HNLocalizedString(@"HNChannelReconnectError")];
    }
}

#pragma mark - Auth Alert
- (void)showAuthorizationAlertWithURL:(NSURL *)url {
    HNAlertController *alertController = [[HNAlertController alloc] initWithTitle:HNLocalizedString(@"HNChannelEnableJointDebugging") message:nil preferredStyle:HNAlertControllerStyleAlert];
    __weak HNChannelMatchManager *weakSelf = self;
    [alertController addActionWithTitle:HNLocalizedString(@"HNAlertOK") style:HNAlertActionStyleDefault handler:^(HNAlertAction * _Nonnull action) {
        __strong HNChannelMatchManager *strongSelf = weakSelf;
        if ([strongSelf isValidForChannelDebug] && [strongSelf isValidOfDeviceInfo]) {
            NSDictionary *qureyItems = [HNURLUtils queryItemsWithURL:url];
            [strongSelf uploadUserInfoIntoWhiteList:qureyItems];
        } else {
            [strongSelf showChannelDebugErrorMessage];
        }
    }];
    [alertController addActionWithTitle:HNLocalizedString(@"HNAlertCancel") style:HNAlertActionStyleCancel handler:nil];
    [alertController show];
}

- (void)uploadUserInfoIntoWhiteList:(NSDictionary *)qureyItems {
    if (![HNReachability sharedInstance].isReachable) {
        [self showErrorMessage:HNLocalizedString(@"HNChannelNetworkError")];
        return;
    }
    NSURLComponents *components = HinaDataSDK.sharedInstance.network.baseURLComponents;
    if (!components) {
        return;
    }
    components.query = nil;
    components.path = [components.path stringByAppendingPathComponent:@"/api/sdk/channel_tool/url"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
    request.timeoutInterval = 60;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:qureyItems];
    params[@"account_id"] = [[HinaDataSDK sharedInstance] distinctId];
    params[@"has_active"] = @([self isAppInstalled]);
    params[@"device_code"] = [self appInstallSource];
    request.HTTPBody = [HNJSONUtil dataWithJSONObject:params];

    [self showIndicator];
    NSURLSessionDataTask *task = [HNHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        NSDictionary *dict;
        if (data) {
            dict = [HNJSONUtil JSONObjectWithData:data];
        }
        NSInteger code = [dict[@"code"] integerValue];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self hideIndicator];
            if (response.statusCode == 200) {
                // 只有当 code 为 1 时表示请求成功
                if (code == 1) {
                    [self showChannelDebugInstall];
                } else {
                    NSString *message = dict[@"message"];
                    HNLogError(@"%@", message);
                    [self showErrorMessage:HNLocalizedString(@"HNChannelRequestWhitelistFailed")];
                }
            } else {
                [self showErrorMessage:HNLocalizedString(@"HNChannelNetworkException")];
            }
        });
    }];
    [task resume];
}

#pragma mark - ChannelDebugInstall Alert
- (void)showChannelDebugInstall {
    NSString *title = HNLocalizedString(@"HNChannelSuccessfullyEnabled");
    NSString *content = HNLocalizedString(@"HNChannelTriggerActivation");
    HNAlertController *alertController = [[HNAlertController alloc] initWithTitle:title message:content preferredStyle:HNAlertControllerStyleAlert];
    [alertController addActionWithTitle:HNLocalizedString(@"HNChannelActivate") style:HNAlertActionStyleDefault handler:^(HNAlertAction * _Nonnull action) {
        dispatch_queue_t serialQueue = HinaDataSDK.sharedInstance.serialQueue;
        // 入队列前，执行动态公共属性采集 block
        [HinaDataSDK.sharedInstance buildDynamicSuperProperties];

        dispatch_async(serialQueue, ^{
            [self trackAppInstall:kHNChannelDebugInstallEventName properties:nil disableCallback:NO];
        });
        [HinaDataSDK.sharedInstance flush];

        [self showChannelDebugInstall];
    }];
    [alertController addActionWithTitle:HNLocalizedString(@"HNAlertCancel") style:HNAlertActionStyleCancel handler:nil];
    [alertController show];
}

#pragma mark - Error Message
- (void)showChannelDebugErrorMessage {
    NSString *title = HNLocalizedString(@"HNChannelDeviceCodeEmpty");
    NSString *content = HNLocalizedString(@"HNChannelTroubleshooting");
    HNAlertController *alertController = [[HNAlertController alloc] initWithTitle:title message:content preferredStyle:HNAlertControllerStyleAlert];
    [alertController addActionWithTitle:HNLocalizedString(@"HNAlertOK") style:HNAlertActionStyleCancel handler:nil];
    [alertController show];
}

- (void)showErrorMessage:(NSString *)errorMessage {
    HNAlertController *alertController = [[HNAlertController alloc] initWithTitle:HNLocalizedString(@"HNAlertHint") message:errorMessage preferredStyle:HNAlertControllerStyleAlert];
    [alertController addActionWithTitle:HNLocalizedString(@"HNAlertOK") style:HNAlertActionStyleCancel handler:nil];
    [alertController show];
}

@end
