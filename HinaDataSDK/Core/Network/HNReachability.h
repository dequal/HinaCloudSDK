//
// HNReachability.h
// HinaDataSDK
//
// Created by hina on 2022/1/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

/**
 HNReachability 是参考 AFNetworkReachabilityManager 实现
 感谢 AFNetworking: https://github.com/AFNetworking/AFNetworking
 */
@interface HNReachability : NSObject

/// 是否有网络连接
@property (readonly, nonatomic, assign, getter = isReachable) BOOL reachable;

/// 当前的网络状态是否为 WIFI
@property (readonly, nonatomic, assign, getter = isReachableViaWiFi) BOOL reachableViaWiFi;

/// 当前的网络状态是否为 WWAN
@property (readonly, nonatomic, assign, getter = isReachableViaWWAN) BOOL reachableViaWWAN;

/// 获取网络触达类的实例
+ (instancetype)sharedInstance;

/// 开始监听网络状态
- (void)startMonitoring;

/// 停止监听网络状态
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
