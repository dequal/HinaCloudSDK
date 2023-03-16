//
// HNDeepLinkProcessor.m
// HinaDataSDK
//
// Created by hina on 2022/12/13.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDeepLinkProcessor.h"
#import "HNDeepLinkConstants.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"
#import "HNIdentifier.h"
#import "HNQueryDeepLinkProcessor.h"
#import "HNRequestDeepLinkProcessor.h"
#import "HNDeepLinkEventProcessor.h"
#import "HNDeferredDeepLinkProcessor.h"

@interface HNDeepLinkLaunchEventObject : HNPresetEventObject

@end

@implementation HNDeepLinkLaunchEventObject

// 手动调用接口采集 H_AppDeeplinkLaunch 事件, 不需要添加 H_latest_utm_xxx 属性
- (void)addLatestUtmProperties:(NSDictionary *)properties {
}

@end

@implementation HNDeepLinkProcessor

+ (BOOL)isValidURL:(NSURL *)url customChannelKeys:(NSSet *)customChannelKeys {
    return NO;
}

- (BOOL)canWakeUp {
    return NO;
}

- (void)startWithProperties:(NSDictionary *)properties {

}

- (NSDictionary *)acquireChannels:(NSDictionary *)dictionary {
    // SDK 预置属性，示例：H_utm_content 和 用户自定义属性
    return [self presetKeyPrefix:@"H_" customKeyPrefix:@"" dictionary:dictionary];
}

- (NSDictionary *)acquireLatestChannels:(NSDictionary *)dictionary {
    // SDK 预置属性，示例：H_latest_utm_content。
    // 用户自定义的属性，不是 SDK 的预置属性，因此以 _latest 开头，避免 HN 平台报错。示例：_lateset_customKey
    return [self presetKeyPrefix:@"H_latest_" customKeyPrefix:@"_latest_" dictionary:dictionary];
}

- (NSDictionary *)presetKeyPrefix:(NSString *)presetKeyPrefix customKeyPrefix:(NSString *)customKeyPrefix dictionary:(NSDictionary *)dictionary {
    if (!presetKeyPrefix || !customKeyPrefix) {
        return @{};
    }

    NSMutableDictionary *channels = [NSMutableDictionary dictionary];
    for (NSString *item in dictionary.allKeys) {
        if ([hinadata_preset_channel_keys() containsObject:item]) {
            NSString *key = [NSString stringWithFormat:@"%@%@", presetKeyPrefix, item];
            channels[key] = [dictionary[item] stringByRemovingPercentEncoding];
        }
        if ([self.customChannelKeys containsObject:item]) {
            NSString *key = [NSString stringWithFormat:@"%@%@", customKeyPrefix, item];
            channels[key] = [dictionary[item] stringByRemovingPercentEncoding];
        }
    }
    return channels;
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

- (void)trackDeepLinkLaunch:(NSDictionary *)properties {
    HNDeepLinkLaunchEventObject *object = [[HNDeepLinkLaunchEventObject alloc] initWithEventId:kHNAppDeepLinkLaunchEvent];
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    [eventProperties addEntriesFromDictionary:properties];
    eventProperties[kHNEventPropertyDeepLinkURL] = self.URL.absoluteString;
    eventProperties[kHNEventPropertyInstallSource] = [self appInstallSource];
    [HinaDataSDK.sharedInstance trackEventObject:object properties:eventProperties];
}

- (void)trackDeepLinkMatchedResult:(NSDictionary *)properties {
    HNPresetEventObject *object = [[HNPresetEventObject alloc] initWithEventId:kHNDeepLinkMatchedResultEvent];
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    [eventProperties addEntriesFromDictionary:properties];
    eventProperties[kHNEventPropertyDeepLinkURL] = self.URL.absoluteString;

    [HinaDataSDK.sharedInstance trackEventObject:object properties:eventProperties];
}

@end

@implementation HNDeepLinkProcessorFactory

+ (HNDeepLinkProcessor *)processorFromURL:(NSURL *)url customChannelKeys:(NSSet *)customChannelKeys {
    HNDeepLinkProcessor *object;
    if ([HNRequestDeepLinkProcessor isValidURL:url customChannelKeys:customChannelKeys]) {
        object = [[HNRequestDeepLinkProcessor alloc] init];
    } else if ([HNQueryDeepLinkProcessor isValidURL:url customChannelKeys:customChannelKeys]) {
        object = [[HNQueryDeepLinkProcessor alloc] init];
    } else {
        object = [[HNDeepLinkProcessor alloc] init];
    }
    object.URL = url;
    object.customChannelKeys = customChannelKeys;
    return object;
}

@end
