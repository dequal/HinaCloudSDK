//
// HNQueryDeepLinkProcessor.m
// HinaDataSDK
//
// Created by hina on 2022/3/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNQueryDeepLinkProcessor.h"
#import "HNDeepLinkConstants.h"
#import "HinaDataSDK+Private.h"
#import "HinaDataSDK+DeepLink.h"
#import "HNConstants+Private.h"
#import "HNURLUtils.h"
#import "HNIdentifier.h"
#import "HNJSONUtil.h"
#import "HNNetwork.h"
#import "HNUserAgent.h"

@implementation HNQueryDeepLinkProcessor

// URL 的 Query 中包含一个或多个 utm_* 参数。示例：https://hinadata.cn?utm_content=1&utm_campaign=2
// utm_* 参数共五个，"utm_campaign", "utm_content", "utm_medium", "utm_source", "utm_term"
+ (BOOL)isValidURL:(NSURL *)url customChannelKeys:(NSSet *)customChannelKeys {
    NSMutableSet *sets = [NSMutableSet setWithSet:customChannelKeys];
    [sets unionSet:hinadata_preset_channel_keys()];
    NSDictionary *queryItems = [HNURLUtils queryItemsWithURL:url];
    for (NSString *key in sets) {
        if (queryItems[key]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)canWakeUp {
    return YES;
}

- (void)startWithProperties:(NSDictionary *)properties {
    NSDictionary *queryItems = [HNURLUtils queryItemsWithURL:self.URL];
    NSDictionary *channels = [self acquireChannels:queryItems];
    NSDictionary *latestChannels = [self acquireLatestChannels:queryItems];
    NSMutableDictionary *eventProperties = [NSMutableDictionary dictionary];
    [eventProperties addEntriesFromDictionary:properties];
    [eventProperties addEntriesFromDictionary:channels];
    [eventProperties addEntriesFromDictionary:latestChannels];
    [self trackDeepLinkLaunch:eventProperties];

    if ([self.delegate respondsToSelector:@selector(sendChannels:latestChannels:isDeferredDeepLink:)]) {
        [self.delegate sendChannels:channels latestChannels:latestChannels isDeferredDeepLink:NO];
    }
}
@end
