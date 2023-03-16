//
// HNCarrierNamePropertyPlugin.m
// HinaDataSDK
//
// Created by  hina on 2022/5/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNCarrierNamePropertyPlugin.h"
#import "HNJSONUtil.h"
#import "HNLog.h"
#import "HNConstants+Private.h"
#import "HNLimitKeyManager.h"
#import "HNValidator.h"

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif

/// 运营商名称
static NSString * const kHNEventPresetPropertyCarrier = @"H_carrier";

@interface HNCarrierNamePropertyPlugin()
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
@property (nonatomic, strong) CTTelephonyNetworkInfo *networkInfo;
#endif
@end
@implementation HNCarrierNamePropertyPlugin

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#pragma mark - private method
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
        _networkInfo = [HNCarrierNamePropertyPlugin sharedNetworkInfo];
    }
    return self;
}

- (void)dealloc {
    self.networkInfo = nil;
}

- (NSString *)currentCarrierName {
    NSString *carrierName = nil;

    @try {
        CTCarrier *carrier = nil;

#ifdef __IPHONE_12_0
        if (@available(iOS 12.1, *)) {
            // 排序
            NSArray *carrierKeysArray = [self.networkInfo.serviceSubscriberCellularProviders.allKeys sortedArrayUsingSelector:@selector(compare:)];
            carrier = self.networkInfo.serviceSubscriberCellularProviders[carrierKeysArray.firstObject];
            if (!carrier.mobileNetworkCode) {
                carrier = self.networkInfo.serviceSubscriberCellularProviders[carrierKeysArray.lastObject];
            }
        }
#endif
        if (!carrier) {
            carrier = self.networkInfo.subscriberCellularProvider;
        }
        if (carrier != nil) {
            NSString *networkCode = [carrier mobileNetworkCode];
            NSString *countryCode = [carrier mobileCountryCode];

            // 中国运营商 mcc 标识
            NSString *carrierChinaMCC = @"460";

            //中国运营商
            if (countryCode && [countryCode isEqualToString:carrierChinaMCC] && networkCode) {
                //中国移动
                if ([networkCode isEqualToString:@"00"] || [networkCode isEqualToString:@"02"] || [networkCode isEqualToString:@"07"] || [networkCode isEqualToString:@"08"]) {
                    carrierName = HNLocalizedString(@"HNPresetPropertyCarrierMobile");
                }
                //中国联通
                if ([networkCode isEqualToString:@"01"] || [networkCode isEqualToString:@"06"] || [networkCode isEqualToString:@"09"]) {
                    carrierName = HNLocalizedString(@"HNPresetPropertyCarrierUnicom");
                }
                //中国电信
                if ([networkCode isEqualToString:@"03"] || [networkCode isEqualToString:@"05"] || [networkCode isEqualToString:@"11"]) {
                    carrierName = HNLocalizedString(@"HNPresetPropertyCarrierTelecom");
                }
                //中国卫通
                if ([networkCode isEqualToString:@"04"]) {
                    carrierName = HNLocalizedString(@"HNPresetPropertyCarrierSatellite");
                }
                //中国铁通
                if ([networkCode isEqualToString:@"20"]) {
                    carrierName = HNLocalizedString(@"HNPresetPropertyCarrierTietong");
                }
            } else if (countryCode && networkCode) { //国外运营商解析
                //加载当前 bundle
                NSBundle *hinaBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"HinaDataSDK" ofType:@"bundle"]];
                //文件路径
                NSString *jsonPath = [hinaBundle pathForResource:@"sa_mcc_mnc_mini.json" ofType:nil];
                NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
                NSDictionary *dicAllMcc = [HNJSONUtil JSONObjectWithData:jsonData];
                if (dicAllMcc) {
                    NSString *mccMncKey = [NSString stringWithFormat:@"%@%@", countryCode, networkCode];
                    carrierName = dicAllMcc[mccMncKey];
                }
            }
        }
    } @catch (NSException *exception) {
        HNLogError(@"%@: %@", self, exception);
    }
    return carrierName;
}
#endif

#pragma mark - HNPropertyPlugin method

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    return filter.type & HNEventTypeDefault;
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    NSString *carrier = [HNLimitKeyManager carrier];
    if ([HNValidator isValidString:carrier]) {
        return @{kHNEventPresetPropertyCarrier: carrier};
    }
    NSMutableDictionary *props = [NSMutableDictionary dictionary];
#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
    props[kHNEventPresetPropertyCarrier] = [self currentCarrierName];
#endif
    return [props copy];
}

@end
