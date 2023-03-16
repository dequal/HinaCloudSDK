//
// HNRemoteConfigCommonOperator.m
// HinaDataSDK
//
// Created by hina on 2022/7/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNRemoteConfigCommonOperator.h"
#import "HNReachability.h"
#import "HNLog.h"
#import "HNValidator.h"
#import "HNStoreManager.h"
#import "HNModuleManager.h"
#import "HNConfigOptions+RemoteConfig.h"
#if __has_include("HNConfigOptions+Encrypt.h")
#import "HNConfigOptions+Encrypt.h"
#endif

typedef NS_ENUM(NSInteger, HNRemoteConfigHandleRandomTimeType) {
    HNRemoteConfigHandleRandomTimeTypeCreate, // 创建分散请求时间
    HNRemoteConfigHandleRandomTimeTypeRemove, // 移除分散请求时间
    HNRemoteConfigHandleRandomTimeTypeNone    // 不处理分散请求时间
};

static NSString * const kSDKConfigKey = @"HNSDKConfig";
static NSString * const kRequestRemoteConfigRandomTimeKey = @"HNRequestRemoteConfigRandomTime"; // 保存请求远程配置的随机时间 @{@"randomTime":@double,@"startDeviceTime":@double}
static NSString * const kRandomTimeKey = @"randomTime";
static NSString * const kStartDeviceTimeKey = @"startDeviceTime";

@interface HNRemoteConfigCommonOperator ()

@property (nonatomic, assign) NSUInteger requestRemoteConfigRetryMaxCount; // 请求远程配置的最大重试次数

@end

@implementation HNRemoteConfigCommonOperator

#pragma mark - Life Cycle

- (instancetype)initWithConfigOptions:(HNConfigOptions *)configOptions remoteConfigModel:(HNRemoteConfigModel *)model {
    self = [super initWithConfigOptions:configOptions remoteConfigModel:model];
    if (self) {
        _requestRemoteConfigRetryMaxCount = 3;
        [self enableLocalRemoteConfig];
    }
    return self;
}

#pragma mark - Protocol

- (void)enableLocalRemoteConfig {
    NSDictionary *config = [[HNStoreManager sharedInstance] objectForKey:kSDKConfigKey];
    [self enableRemoteConfig:config];
}

- (void)tryToRequestRemoteConfig {
    // 触发远程配置请求的三个条件
    // 1. 判断是否禁用分散请求，如果禁用则直接请求，同时将本地存储的随机时间清除
    if (self.configOptions.disableRandomTimeRequestRemoteConfig || self.configOptions.maxRequestHourInterval < self.configOptions.minRequestHourInterval) {
        [self requestRemoteConfigWithHandleRandomTimeType:HNRemoteConfigHandleRandomTimeTypeRemove isForceUpdate:NO];
        HNLogDebug(@"【remote config】Request remote config because disableRandomTimeRequestRemoteConfig or minHourInterval greater than maxHourInterval");
        return;
    }
    
    // 2. 如果开启加密并且未设置公钥（新用户安装或者从未加密版本升级而来），则请求远程配置获取公钥，同时本地生成随机时间
#if __has_include("HNConfigOptions+Encrypt.h")
    if (self.configOptions.enableEncrypt && !HNModuleManager.sharedInstance.hasSecretKey) {
        [self requestRemoteConfigWithHandleRandomTimeType:HNRemoteConfigHandleRandomTimeTypeCreate isForceUpdate:NO];
        HNLogDebug(@"【remote config】Request remote config because encrypt builder is nil");
        return;
    }
#endif

    // 获取本地保存的随机时间和设备启动时间
    NSDictionary *requestTimeConfig = [[HNStoreManager sharedInstance] objectForKey:kRequestRemoteConfigRandomTimeKey];
    double randomTime = [[requestTimeConfig objectForKey:kRandomTimeKey] doubleValue];
    double startDeviceTime = [[requestTimeConfig objectForKey:kStartDeviceTimeKey] doubleValue];
    // 获取当前设备启动时间，以开机时间为准，单位：秒
    NSTimeInterval currentTime = NSProcessInfo.processInfo.systemUptime;
    
    // 3. 如果设备重启过或满足分散请求的条件，则强制请求远程配置，同时本地生成随机时间
    if ((currentTime < startDeviceTime) || (currentTime >= randomTime)) {
        [self requestRemoteConfigWithHandleRandomTimeType:HNRemoteConfigHandleRandomTimeTypeCreate isForceUpdate:NO];
        HNLogDebug(@"【remote config】Request remote config because the device has been restarted or satisfy the random request condition");
    }
}

- (void)cancelRequestRemoteConfig {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 还未发出请求
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    });
}

- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate {
    [self cancelRequestRemoteConfig];
    [self requestRemoteConfigWithHandleRandomTimeType:HNRemoteConfigHandleRandomTimeTypeCreate isForceUpdate:isForceUpdate];
}

#pragma mark - Private Methods

#pragma mark RandomTime

- (void)handleRandomTimeWithType:(HNRemoteConfigHandleRandomTimeType)type {
    switch (type) {
        case HNRemoteConfigHandleRandomTimeTypeCreate:
            [self createRandomTime];
            break;
            
        case HNRemoteConfigHandleRandomTimeTypeRemove:
            [self removeRandomTime];
            break;
            
        default:
            break;
    }
}

- (void)createRandomTime {
    // 当前时间，以开机时间为准，单位：秒
    NSTimeInterval currentTime = NSProcessInfo.processInfo.systemUptime;
    
    // 计算实际间隔时间（此时只需要考虑 minRequestHourInterval <= maxRequestHourInterval 的情况）
    double realIntervalTime = self.configOptions.minRequestHourInterval * 60 * 60;
    if (self.configOptions.maxRequestHourInterval > self.configOptions.minRequestHourInterval) {
        // 转换成 秒 再取随机时间
        double durationSecond = (self.configOptions.maxRequestHourInterval - self.configOptions.minRequestHourInterval) * 60 * 60;
        
        // arc4random_uniform 的取值范围，是左闭右开，所以 +1
        realIntervalTime += arc4random_uniform(durationSecond + 1);
    }
    
    // 触发请求后，生成下次随机触发时间
    double randomTime = currentTime + realIntervalTime;
    
    NSDictionary *createRequestTimeConfig = @{kRandomTimeKey: @(randomTime), kStartDeviceTimeKey: @(currentTime) };
    [[HNStoreManager sharedInstance] setObject:createRequestTimeConfig forKey:kRequestRemoteConfigRandomTimeKey];
}

- (void)removeRandomTime {
    [[HNStoreManager sharedInstance] removeObjectForKey:kRequestRemoteConfigRandomTimeKey];
}

#pragma mark Request

- (void)requestRemoteConfigWithHandleRandomTimeType:(HNRemoteConfigHandleRandomTimeType)type isForceUpdate:(BOOL)isForceUpdate {
    @try {
        [self requestRemoteConfigWithDelay:0 index:0 isForceUpdate:isForceUpdate];
        [self handleRandomTimeWithType:type];
    } @catch (NSException *exception) {
        HNLogError(@"【remote config】%@ error: %@", self, exception);
    }
}

- (void)requestRemoteConfigWithDelay:(NSTimeInterval)delay index:(NSUInteger)index isForceUpdate:(BOOL)isForceUpdate {
    __weak typeof(self) weakSelf = self;
    void(^completion)(BOOL success, NSDictionary<NSString *, id> *config) = ^(BOOL success, NSDictionary<NSString *, id> *config) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        @try {
            HNLogDebug(@"【remote config】The request result: success is %d, config is %@", success, config);
            
            if (success) {
                if(config != nil) {
                    // 加密
#if __has_include("HNConfigOptions+Encrypt.h")
                    if (strongSelf.configOptions.enableEncrypt) {
                        NSDictionary<NSString *, id> *encryptConfig = [strongSelf extractEncryptConfig:config];
                        [HNModuleManager.sharedInstance handleEncryptWithConfig:encryptConfig];
                    }
#endif
                    // 远程配置的请求回调需要在主线程做一些操作（定位和设备方向等）
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSDictionary<NSString *, id> *remoteConfig = [strongSelf extractRemoteConfig:config];
                        [strongSelf handleRemoteConfig:remoteConfig];
                    });
                }
            } else {
                if (index < strongSelf.requestRemoteConfigRetryMaxCount - 1) {
                    [strongSelf requestRemoteConfigWithDelay:30 index:index + 1 isForceUpdate:isForceUpdate];
                }
            }
        } @catch (NSException *e) {
            HNLogError(@"【remote config】%@ error: %@", strongSelf, e);
        }
    };
    
    // 子线程不会主动开启 runloop，因此这里切换到主线程执行
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *params = @{@"isForceUpdate" : @(isForceUpdate), @"completion" : completion};
        [self performSelector:@selector(requestRemoteConfigWithParams:) withObject:params afterDelay:delay inModes:@[NSRunLoopCommonModes, NSDefaultRunLoopMode]];
    });
}

- (void)requestRemoteConfigWithParams:(NSDictionary *)params {
    BOOL isForceUpdate = [params[@"isForceUpdate"] boolValue];
    void(^completion)(BOOL success, NSDictionary<NSString *, id> *config) = params[@"completion"];

    if (![HNReachability sharedInstance].isReachable) {
        if (completion) {
            completion(NO, nil);
        }
        return;
    }

    [self requestRemoteConfigWithForceUpdate:isForceUpdate completion:completion];
}

- (void)handleRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig {
    // 在接收到请求时会异步切换到主线程中，为了保证程序稳定，添加 try-catch 保护
    @try {
        if ([HNValidator isValidDictionary:remoteConfig]) {
            [self updateLocalLibVersion];
            [self trackAppRemoteConfigChanged:remoteConfig];
            [self saveRemoteConfig:remoteConfig];
            [self triggerRemoteConfigEffect:remoteConfig];
        }
    } @catch (NSException *exception) {
        HNLogError(@"【remote config】%@ error: %@", self, exception);
    }
}

- (void)updateLocalLibVersion {
    self.model.localLibVersion = HinaDataSDK.sdkInstance.libVersion;
}

- (void)saveRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig {
    [[HNStoreManager sharedInstance] setObject:[self addLibVersionToRemoteConfig:remoteConfig] forKey:kSDKConfigKey];
}

- (void)triggerRemoteConfigEffect:(NSDictionary<NSString *, id> *)remoteConfig {
    NSNumber *effectMode = remoteConfig[@"configs"][@"effect_mode"];
    if ([effectMode integerValue] == HNRemoteConfigEffectModeNow) {
        [self enableRemoteConfig:[self addLibVersionToRemoteConfig:remoteConfig]];
    }
}

- (NSDictionary<NSString *, id> *)addLibVersionToRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig {
    // 手动添加当前 SDK 版本号
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithDictionary:remoteConfig];
    result[@"localLibVersion"] = HinaDataSDK.sdkInstance.libVersion;
    return result;
}

@end

