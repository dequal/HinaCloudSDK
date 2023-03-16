//
// HNReferrerManager.m
// HinaDataSDK
//
// Created by hina on 2022/12/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNReferrerManager.h"
#import "HNConstants+Private.h"

@interface HNReferrerManager ()

@property (atomic, copy, readwrite) NSDictionary *referrerProperties;
@property (atomic, copy, readwrite) NSString *referrerURL;
@property (nonatomic, copy, readwrite) NSString *referrerTitle;
@property (nonatomic, copy) NSString *currentTitle;

@end

@implementation HNReferrerManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HNReferrerManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNReferrerManager alloc] init];
    });
    return manager;
}

- (NSDictionary *)propertiesWithURL:(NSString *)currentURL eventProperties:(NSDictionary *)eventProperties {
    NSString *referrerURL = self.referrerURL;
    NSMutableDictionary *newProperties = [NSMutableDictionary dictionaryWithDictionary:eventProperties];

    // 客户自定义属性中包含 $url 时，以客户自定义内容为准
    if (!newProperties[kHNEventPropertyScreenUrl]) {
        newProperties[kHNEventPropertyScreenUrl] = currentURL;
    }
    // 客户自定义属性中包含 $referrer 时，以客户自定义内容为准
    if (referrerURL && !newProperties[kHNEventPropertyScreenReferrerUrl]) {
        newProperties[kHNEventPropertyScreenReferrerUrl] = referrerURL;
    }
    // $referrer 内容以最终页面浏览事件中的 $url 为准
    self.referrerURL = newProperties[kHNEventPropertyScreenUrl];
    self.referrerProperties = newProperties;

    dispatch_async(self.serialQueue, ^{
        [self cacheReferrerTitle:newProperties];
    });
    return newProperties;
}

- (void)cacheReferrerTitle:(NSDictionary *)properties {
    self.referrerTitle = self.currentTitle;
    self.currentTitle = properties[kHNEventPropertyTitle];
}

- (void)clearReferrer {
    if (self.isClearReferrer) {
        // 需求层面只需要清除 $referrer，不需要清除 $referrer_title
        self.referrerURL = nil;
    }
}

@end
