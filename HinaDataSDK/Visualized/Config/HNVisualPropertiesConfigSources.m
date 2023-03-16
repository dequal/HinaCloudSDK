//
// HNVisualPropertiesConfigSources.m
// HinaDataSDK
//
// Created by hina on 2022/1/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNVisualPropertiesConfigSources.h"
#import "UIViewController+HNAutoTrack.h"
#import "HNConstants+Private.h"
#import "HNReadWriteLock.h"
#import "HNReachability.h"
#import "HNStoreManager.h"
#import "HNURLUtils.h"
#import "HNVisualizedLogger.h"
#import "HNJSONUtil.h"
#import "HNLog.h"

static NSString * kHNConfigFileName = @"HNVisualPropertiesConfig";
static NSString * kHNRequestConfigPath = @"config/visualized/iOS.conf";

static NSInteger const kHNRequestConfigMaxTimes = 3;
typedef void(^HNVisualPropertiesConfigCompletionHandler)(BOOL success, HNVisualPropertiesResponse *_Nullable responseData);

/// 重试请求时间间隔，单位 秒
static NSTimeInterval const kRequestconfigRetryIntervalTime = 30;

@interface HNVisualPropertiesConfigSources()

/// 完整配置数据
@property (atomic, strong) HNVisualPropertiesResponse *configResponse;

@property(weak, nonatomic, nullable) id<HNConfigChangesDelegate> delegate;
@end

@implementation HNVisualPropertiesConfigSources

#pragma mark - initialize
- (instancetype)initWithDelegate:(id<HNConfigChangesDelegate>)delegate {
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

#pragma mark - loadConfig
- (void)loadConfig {
    // 解析本地缓存
    [self unarchiveConfig];

    // 更新配置状态
    [self updateConfigStatus];

    //请求配置数据，失败则重试
    [self requestConfigWithTimes:kHNRequestConfigMaxTimes];
}

- (void)setupConfigWithDictionary:(NSDictionary *)configDic disableConfig:(BOOL)disable {
    if (disable) { // 关闭自定义属性
        [self archiveConfig:nil];
    } else {
        HNVisualPropertiesResponse *config = [[HNVisualPropertiesResponse alloc] initWithDictionary:configDic];
        // 缓存数据
        [self archiveConfig:config];
    }
    
    // 更新配置状态
    [self updateConfigStatus];
}

// 刷新配置
- (void)reloadConfig {
    // 更新最新缓存，并清除本地配置
    [self cleanConfig];

    NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"reset serverURL and clear configuration cache"];
    HNLogDebug(@"%@", logMessage);

    [self updateConfigStatus];

    [self requestConfigWithTimes:kHNRequestConfigMaxTimes];
}

/// 更新配置结果状态
- (void)updateConfigStatus {
    if ([self.delegate respondsToSelector:@selector(configChangedWithValid:)]) {
        [self.delegate configChangedWithValid:(self.isValid)];
    }
}

- (BOOL)isValid {
    return self.configResponse.originalResponse.count > 0;
}

- (NSString *)configVersion {
    return self.configResponse.version;
}

- (NSDictionary *)originalResponse {
    return self.configResponse.originalResponse;
}

#pragma mark - request
- (void)requestConfigWithTimes:(NSInteger)times {
    NSInteger requestIndex = times - 1;

    [self requestConfigWithCompletionHandler:^(BOOL success, HNVisualPropertiesResponse *_Nullable responseData) {
        if (requestIndex <= 0 || success) {
            return;
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRequestconfigRetryIntervalTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self requestConfigWithTimes:requestIndex];
        });
    }];
}

- (void)requestConfigWithCompletionHandler:(HNVisualPropertiesConfigCompletionHandler)completionHandler {

    // HNReachability 同步网络判断存在延迟，冷启动后立即判断，可能误判为 NO
    //    if (![HNReachability sharedInstance].reachable) {
    //        HNLogWarn(@"The current network is unavailable, please check the network !");
    //        completionHandler(NO, nil);
    //        return;
    //    }
    
    // 拼接请求参数
    NSURLRequest *request = [self buildConfigRequest];
    if (!request) {
        return;
    }
    // 请求最新配置
    NSURLSessionDataTask *task = [HNHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        NSInteger statusCode = response.statusCode;
        /* statusCode 说明
         200：正常请求并正确返回配置，或删除全部可视化全埋点事件（events 字段为空数组）
         304：如果本地配置和后端最新版本相同，则返回 304，同时配置为空
         205：配置不存在（未创建可视化全埋点事件或运维关闭自定义属性），此时配置为空，返回 205
         404：当前环境未包含此接口，可能 HN 版本比较低，暂不支持自定义属性
         */
        BOOL success = statusCode == 200 || statusCode == 304 || statusCode == 205 || statusCode == 404;
        HNVisualPropertiesResponse *config = nil;
        
        if (statusCode == 200) {
            @try {
                NSDictionary *dic = [HNJSONUtil JSONObjectWithData:data];
                if (dic) {
                    NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"get visualized configuration success %@", dic];
                    HNLogInfo(@"【request visualProperties config】%@", logMessage);
                }
                
                HNVisualPropertiesResponse *config = [[HNVisualPropertiesResponse alloc] initWithDictionary:dic];
                
                // 缓存数据
                [self archiveConfig:config];
                
                // 更新配置状态
                [self updateConfigStatus];
            } @catch (NSException *exception) {
                NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"get visualized configuration, JSON parsing failed %@", exception];
                HNLogError(@"【request visualProperties config】%@", logMessage);
            }
        } else if (statusCode == 205) { // 配置不存在（未创建可视化全埋点事件或运维关闭自定义属性）
            // 清空配置
            [self cleanConfig];
            // 更新配置状态
            [self updateConfigStatus];

            NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"configuration does not exist (the current project has not created visualized events or the operations closed custom properties), statusCode = %ld", (long)statusCode];
            HNLogDebug(@"【request visualProperties config】%@", logMessage);
        } else if (statusCode > 200 && statusCode < 300) {
            NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"request configuration exception, statusCode = %ld",(long)statusCode];
            HNLogWarn(@"【request visualProperties config】%@", logMessage);
        } else if (statusCode == 304) { // 未更新
            NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"visualized configuration is not updated, statusCode = %ld", (long)statusCode];
            HNLogDebug(@"【request visualProperties config】%@", logMessage);
        } else if (statusCode == 404) {
            NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:[NSString stringWithFormat:@"request configuration failed, the current environment may not support custom properties, statusCode = %ld", (long)statusCode]];
            HNLogDebug(@"【request visualProperties config】%@", logMessage);
        } else {
            NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"request configuration error: %@",error];
            HNLogError(@"【request visualProperties config】%@", logMessage);
        }
        completionHandler(success, config);
    }];
    [task resume];
}

/// buildRequest
- (NSURLRequest *)buildConfigRequest {

    NSURLComponents *components = HinaDataSDK.sharedInstance.network.baseURLComponents;
    if (!components) {
        NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"serverURL is invalid: %@", HinaDataSDK.sharedInstance.network.serverURL];
        HNLogError(@"%@", logMessage);
        return nil;
    }

    components.query = nil;
    components.path = [components.path stringByAppendingPathComponent:kHNRequestConfigPath];

    // 拼接参数
    NSMutableDictionary<NSString *, id> *params = [NSMutableDictionary dictionary];
    params[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    params[@"project"] = HinaDataSDK.sharedInstance.network.project;

    // 当前配置版本
    if (self.configResponse) {
        params[@"v"] = self.configResponse.version;
    }

    // 拼接 queryItems
    NSString *queryItems =  [HNURLUtils urlQueryStringWithParams:params];
    components.query = queryItems;

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"GET"];

    return request;
}

#pragma mark - archive
/// 解析本地本地缓存
- (void)unarchiveConfig {
    NSString *project = HinaDataSDK.sharedInstance.network.project;

    NSData *data = [[HNStoreManager sharedInstance] objectForKey:kHNConfigFileName];
    HNVisualPropertiesResponse *config = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    if (!config) {
        NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"there is no visualized configuration cache locally"];
        HNLogDebug(@"%@", logMessage);
        return;
    }

    // 合法性校验
    if ([config.project isEqualToString:project] && [config.os isEqualToString:@"iOS"]) {
        self.configResponse = config;

        NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"get local configuration successfully: %@", config.originalResponse];
        HNLogInfo(@"%@", logMessage);
    } else {
        NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"the local cache visualized configuration verification failed, the App project is %@, the cache configuration project is %@, the cache configuration os is %@", project, config.project, config.os];
        HNLogWarn(@"%@", logMessage);
    }
}

/// 写入本地缓存
- (void)archiveConfig:(HNVisualPropertiesResponse *)config {
    // 存储到本地
    self.configResponse = config;

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:config];
    [[HNStoreManager sharedInstance] setObject:data forKey:kHNConfigFileName];
}

/// 清除配置缓存
- (void)cleanConfig {
    self.configResponse = nil;
    // 清除文件缓存
    [[HNStoreManager sharedInstance] removeObjectForKey:kHNConfigFileName];
}

#pragma mark - queryConfig
/// 查询 view 配置
- (nullable NSArray <HNVisualPropertiesConfig *> *)propertiesConfigsWithViewNode:(HNViewNode *)viewNode {
    NSArray<HNVisualPropertiesConfig *> *configSources = self.configResponse.events;
    if (configSources.count == 0 || !viewNode) {
        return nil;
    }

    NSMutableArray *configs = [NSMutableArray array];
    // 查询元素点击事件配置
    for (HNVisualPropertiesConfig *config in configSources) {
        // 普通可视化全埋点事件，不包含自定义属性，直接跳过
        if ((config.properties.count == 0 && config.webProperties.count == 0) || !config.event) {
            continue;
        }
        // 命中配置信息
        if (config.eventType == HinaDataEventTypeAppClick && [config.event isMatchVisualEventWithViewIdentify:viewNode]) {
            [configs addObject:config];
        }
    }
    return configs.count > 0 ? configs : nil;
}

/// 根据事件信息查询配置
- (nullable NSArray <HNVisualPropertiesConfig *> *)propertiesConfigsWithEventIdentifier:(HNEventIdentifier *)eventIdentifier {

    NSArray<HNVisualPropertiesConfig *> *configSources = self.configResponse.events;
    if (configSources.count == 0 || !eventIdentifier) {
        return nil;
    }
    if (![eventIdentifier.eventName isEqualToString:kHNEventNameAppClick]) {
        return nil;
    }

    NSMutableArray <HNVisualPropertiesConfig *>*configs = [NSMutableArray array];
    for (HNVisualPropertiesConfig *config in configSources) {
        // 命中 AppClick 配置
        if (config.eventType == HinaDataEventTypeAppClick && [config.event isMatchVisualEventWithViewIdentify:eventIdentifier]) {
            [configs addObject:config];
        }
    }
    return configs.count > 0 ? [configs copy] : nil;
}

@end
