//
// UIApplication+HNPushClick.m
// HinaDataSDK
//
// Created by hina on 2022/1/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIApplication+HNPushClick.h"
#import "HNApplicationDelegateProxy.h"
#import <objc/runtime.h>

static void *const kHNLaunchOptions = (void *)&kHNLaunchOptions;

@implementation UIApplication (PushClick)

- (void)hinadata_setDelegate:(id<UIApplicationDelegate>)delegate {
    //resolve optional selectors
    [HNApplicationDelegateProxy resolveOptionalSelectorsForDelegate:delegate];
    
    [self hinadata_setDelegate:delegate];
    
    if (!self.delegate) {
        return;
    }
    [HNApplicationDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"application:didReceiveLocalNotification:", @"application:didReceiveRemoteNotification:fetchCompletionHandler:"]]];
}

- (NSDictionary *)hinadata_launchOptions {
    return objc_getAssociatedObject(self, kHNLaunchOptions);
}

- (void)setHinadata_launchOptions:(NSDictionary *)hinadata_launchOptions {
    objc_setAssociatedObject(self, kHNLaunchOptions, hinadata_launchOptions, OBJC_ASSOCIATION_COPY);
}

@end
