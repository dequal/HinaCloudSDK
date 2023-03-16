//
// HNNotificationUtil.m
// HinaDataSDK
//
// Created by hina on 2022/1/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNNotificationUtil.h"
#import "HNAppPushConstants.h"
#import "HNJSONUtil.h"
#import "HNLog.h"

@implementation HNNotificationUtil

+ (NSDictionary *)propertiesFromUserInfo:(NSDictionary *)userInfo {
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    
    if (userInfo[kHNPushServiceKeyJPUSH]) {
        properties[kHNEventPropertyNotificationServiceName] = kHNEventPropertyNotificationServiceNameJPUSH;
    }
    
    if (userInfo[kHNPushServiceKeyGeTui]) {
        properties[kHNEventPropertyNotificationServiceName] = kHNEventPropertyNotificationServiceNameGeTui;
    }
    
    //SF related properties
    NSString *sfDataString = userInfo[kHNPushServiceKeySF];
    
    if ([sfDataString isKindOfClass:[NSString class]]) {

        NSDictionary *sfProperties = [HNJSONUtil JSONObjectWithString:sfDataString];
        if ([sfProperties isKindOfClass:[NSDictionary class]]) {
            [properties addEntriesFromDictionary:[self propertiesFromSFData:sfProperties]];
        }
    }
    
    return [properties copy];
}

+ (NSDictionary *)propertiesFromSFData:(NSDictionary *)sfData {
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[kSFPlanStrategyID] = sfData[kSFPlanStrategyID.hinadata_sfPushKey];
    properties[kSFChannelCategory] = sfData[kSFChannelCategory.hinadata_sfPushKey];
    properties[kSFAudienceID] = sfData[kSFAudienceID.hinadata_sfPushKey];
    properties[kSFChannelID] = sfData[kSFChannelID.hinadata_sfPushKey];
    properties[kSFLinkUrl] = sfData[kSFLinkUrl.hinadata_sfPushKey];
    properties[kSFPlanType] = sfData[kSFPlanType.hinadata_sfPushKey];
    properties[kSFChannelServiceName] = sfData[kSFChannelServiceName.hinadata_sfPushKey];
    properties[kSFMessageID] = sfData[kSFMessageID.hinadata_sfPushKey];
    properties[kSFPlanID] = sfData[kSFPlanID.hinadata_sfPushKey];
    properties[kSFStrategyUnitID] = sfData[kSFStrategyUnitID.hinadata_sfPushKey];
    properties[kSFEnterPlanTime] = sfData[kSFEnterPlanTime.hinadata_sfPushKey];
    return [properties copy];
}

@end

@implementation NSString (SFPushKey)

- (NSString *)hinadata_sfPushKey {
    NSString *prefix = @"H_";
    if ([self hasPrefix:prefix]) {
        return [self substringFromIndex:[prefix length]];
    }
    return self;
}

@end
