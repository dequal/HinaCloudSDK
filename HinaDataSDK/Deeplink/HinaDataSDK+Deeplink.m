//
// HinaDataSDK+DeepLink.m
// HinaDataSDK
//
// Created by hina on 2022/9/11.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HinaDataSDK+DeepLink.h"
#import "HNDeepLinkManager.h"
#import "HNConstants+Private.h"
#import "HNLog.h"

@implementation HNDeepLinkObject

@end

@implementation HinaDataSDK (DeepLink)

- (void)setDeeplinkCallback:(void(^)(NSString *_Nullable params, BOOL success, NSInteger appAwakePassedTime))callback {
    if (!callback) {
        return;
    }
    HNDeepLinkManager.defaultManager.oldCompletion = ^BOOL(HNDeepLinkObject * _Nonnull object) {
        callback(object.params, object.success, object.appAwakePassedTime);
        return NO;
    };
}

- (void)requestDeferredDeepLink:(NSDictionary *)properties {
    [HNDeepLinkManager.defaultManager requestDeferredDeepLink:properties];
}

- (void)setDeepLinkCompletion:(BOOL(^)(HNDeepLinkObject *obj))completion {
    if (!completion) {
        return;
    }
    HNDeepLinkManager.defaultManager.completion = completion;
}

- (void)trackDeepLinkLaunchWithURL:(NSString *)url {
    [[HNDeepLinkManager defaultManager] trackDeepLinkLaunchWithURL:url];
}

@end
