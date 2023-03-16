//
// HNNetworkInfoPropertyPlugin.m
// HinaDataSDK
//
// Created by hina on 2022/3/11.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNNetworkInfoPropertyPlugin.h"
#import "HNLog.h"
#import "HNJSONUtil.h"
#import "HNReachability.h"

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

/// 网络类型
static NSString * const kHNEventPresetPropertyNetworkType = @"H_network_type";
/// 是否 WI-FI
static NSString * const kHNEventPresetPropertyWifi = @"H_wifi";


@interface HNNetworkInfoPropertyPlugin ()

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
@property (nonatomic, strong) CTTelephonyNetworkInfo *networkInfo;
#endif

@end

@implementation HNNetworkInfoPropertyPlugin

#pragma mark - private method
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST

+ (CTTelephonyNetworkInfo *)sharedNetworkInfo {
    static CTTelephonyNetworkInfo *networkInfo;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    });
    return networkInfo;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _networkInfo = [HNNetworkInfoPropertyPlugin sharedNetworkInfo];
    }
    return self;
}

- (void)dealloc {
    self.networkInfo = nil;
}

- (HinaDataNetworkType)networkTypeWWANOptionsWithString:(NSString *)networkTypeString {
    if ([@"2G" isEqualToString:networkTypeString]) {
        return HinaDataNetworkType2G;
    } else if ([@"3G" isEqualToString:networkTypeString]) {
        return HinaDataNetworkType3G;
    } else if ([@"4G" isEqualToString:networkTypeString]) {
        return HinaDataNetworkType4G;
#ifdef __IPHONE_14_1
    } else if ([@"5G" isEqualToString:networkTypeString]) {
        return HinaDataNetworkType5G;
#endif
    } else if ([@"UNKNOWN" isEqualToString:networkTypeString]) {
        return HinaDataNetworkType4G;
    }
    return HinaDataNetworkTypeNONE;
}

- (NSString *)networkTypeWWANString {
    if (![HNReachability sharedInstance].isReachableViaWWAN) {
        return @"NULL";
    }

    NSString *currentRadioAccessTechnology = nil;
#ifdef __IPHONE_12_0
    if (@available(iOS 12.1, *)) {
        currentRadioAccessTechnology = self.networkInfo.serviceCurrentRadioAccessTechnology.allValues.lastObject;
    }
#endif
    // 测试发现存在少数 12.0 和 12.0.1 的机型 serviceCurrentRadioAccessTechnology 返回空
    if (!currentRadioAccessTechnology) {
        currentRadioAccessTechnology = self.networkInfo.currentRadioAccessTechnology;
    }

    return [self networkStatusWithRadioAccessTechnology:currentRadioAccessTechnology];
}

- (NSString *)networkStatusWithRadioAccessTechnology:(NSString *)value {
    if ([value isEqualToString:CTRadioAccessTechnologyGPRS] ||
        [value isEqualToString:CTRadioAccessTechnologyEdge]
        ) {
        return @"2G";
    } else if ([value isEqualToString:CTRadioAccessTechnologyWCDMA] ||
               [value isEqualToString:CTRadioAccessTechnologyHSDPA] ||
               [value isEqualToString:CTRadioAccessTechnologyHSUPA] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMA1x] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA] ||
               [value isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB] ||
               [value isEqualToString:CTRadioAccessTechnologyeHRPD]
               ) {
        return @"3G";
    } else if ([value isEqualToString:CTRadioAccessTechnologyLTE]) {
        return @"4G";
    }

#ifdef __IPHONE_14_1
    else if (@available(iOS 14.1, *)) {
        if ([value isEqualToString:CTRadioAccessTechnologyNRNSA] ||
            [value isEqualToString:CTRadioAccessTechnologyNR]
            ) {
            return @"5G";
        }
    }
#endif
    return @"UNKNOWN";
}

#endif

- (NSString *)networkTypeString {
    NSString *networkTypeString = @"NULL";
    @try {
        if ([HNReachability sharedInstance].isReachableViaWiFi) {
            networkTypeString = @"WIFI";
        }
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
        else {
            networkTypeString = [self networkTypeWWANString];
        }
#endif
    } @catch (NSException *exception) {
        HNLogError(@"%@: %@", self, exception);
    }
    return networkTypeString;
}

#pragma mark - public method
/// 当前的网络类型
- (HinaDataNetworkType)currentNetworkTypeOptions {
    NSString *networkTypeString = [self networkTypeString];

    if ([@"NULL" isEqualToString:networkTypeString]) {
        return HinaDataNetworkTypeNONE;
    } else if ([@"WIFI" isEqualToString:networkTypeString]) {
        return HinaDataNetworkTypeWIFI;
    }

    HinaDataNetworkType networkType = HinaDataNetworkTypeNONE;
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    networkType = [self networkTypeWWANOptionsWithString:networkTypeString];
#endif
    return networkType;
}

#pragma mark - PropertyPlugin
- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    return filter.type & HNEventTypeDefault;
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityLow;
}

/// 当前的网络属性
- (NSDictionary<NSString *,id> *)properties {
    NSString *networkType = [self networkTypeString];

    NSMutableDictionary *networkProperties = [NSMutableDictionary dictionary];
    networkProperties[kHNEventPresetPropertyNetworkType] = networkType;
    networkProperties[kHNEventPresetPropertyWifi] = @([networkType isEqualToString:@"WIFI"]);
    return networkProperties;
}

@end
