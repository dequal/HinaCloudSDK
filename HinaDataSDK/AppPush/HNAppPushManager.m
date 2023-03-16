//
// HNNotificationManager.m
// HinaDataSDK
//
// Created by hina on 2022/1/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAppPushManager.h"
#import "HNApplicationDelegateProxy.h"
#import "HNSwizzle.h"
#import "HNLog.h"
#import "UIApplication+HNPushClick.h"
#import "HinaDataSDK+Private.h"
#import "HNMethodHelper.h"
#import "HNConfigOptions+AppPush.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import "HNUNUserNotificationCenterDelegateProxy.h"
#endif

@implementation HNAppPushManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNAppPushManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNAppPushManager alloc] init];
    });
    return manager;
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    if (enable) {
        [self proxyNotifications];
    }
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    _configOptions = configOptions;
    [UIApplication sharedApplication].hinadata_launchOptions = configOptions.launchOptions;
    self.enable = configOptions.enableTrackPush;
}

- (void)proxyNotifications {
    //处理未实现代理方法也能采集事件的逻辑
    [HNMethodHelper swizzleRespondsToSelector];
    
    //UIApplicationDelegate proxy
    [HNApplicationDelegateProxy resolveOptionalSelectorsForDelegate:[UIApplication sharedApplication].delegate];
    [HNApplicationDelegateProxy proxyDelegate:[UIApplication sharedApplication].delegate selectors:[NSSet setWithArray:@[@"application:didReceiveLocalNotification:", @"application:didReceiveRemoteNotification:fetchCompletionHandler:"]]];
    
    //UNUserNotificationCenterDelegate proxy
    if (@available(iOS 10.0, *)) {
        if ([UNUserNotificationCenter currentNotificationCenter].delegate) {
            [HNUNUserNotificationCenterDelegateProxy proxyDelegate:[UNUserNotificationCenter currentNotificationCenter].delegate selectors:[NSSet setWithArray:@[@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"]]];
        }
        NSError *error = NULL;
        [UNUserNotificationCenter sa_swizzleMethod:@selector(setDelegate:) withMethod:@selector(hinadata_setDelegate:) error:&error];
        if (error) {
            HNLogError(@"proxy notification delegate error: %@", error);
        }
    }
}

@end
