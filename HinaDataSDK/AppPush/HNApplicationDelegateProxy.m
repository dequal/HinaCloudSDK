//
// HNApplicationDelegateProxy.m
// HinaDataSDK
//
// Created by hina on 2022/1/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNApplicationDelegateProxy.h"
#import "HNClassHelper.h"
#import "NSObject+HNDelegateProxy.h"
#import "UIApplication+HNPushClick.h"
#import "HinaDataSDK.h"
#import "HNAppPushConstants.h"
#import "HNLog.h"
#import "HNNotificationUtil.h"
#import <objc/message.h>

@implementation HNApplicationDelegateProxy

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    SEL selector = @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:);
    [HNApplicationDelegateProxy invokeWithTarget:self selector:selector, application, userInfo, completionHandler];
    [HNApplicationDelegateProxy trackEventWithTarget:self application:application remoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    SEL selector = @selector(application:didReceiveLocalNotification:);
    [HNApplicationDelegateProxy invokeWithTarget:self selector:selector, application, notification];
    [HNApplicationDelegateProxy trackEventWithTarget:self application:application localNotification:notification];
}

+ (void)trackEventWithTarget:(NSObject *)target application:(UIApplication *)application remoteNotification:(NSDictionary *)userInfo {
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != application.delegate) {
        return;
    }
    //track notification
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        HNLogInfo(@"iOS version >= 10.0, callback for %@ was ignored.", @"application:didReceiveRemoteNotification:fetchCompletionHandler:");
        return;
    }
    
    if (application.applicationState != UIApplicationStateInactive) {
        return;
    }
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[kHNEventPropertyNotificationChannel] = kHNEventPropertyNotificationChannelApple;
    
    if (userInfo) {
        NSString *title = nil;
        NSString *content = nil;
        id alert = userInfo[kHNPushAppleUserInfoKeyAps][kHNPushAppleUserInfoKeyAlert];
        if ([alert isKindOfClass:[NSDictionary class]]) {
            title = alert[kHNPushAppleUserInfoKeyTitle];
            content = alert[kHNPushAppleUserInfoKeyBody];
        } else if ([alert isKindOfClass:[NSString class]]) {
            content = alert;
        }
        if (userInfo[kHNPushServiceKeySF]) {
            properties[kSFMessageTitle] = title;
            properties[kSFMessageContent] = content;
        }
        properties[kHNEventPropertyNotificationTitle] = title;
        properties[kHNEventPropertyNotificationContent] = content;
        [properties addEntriesFromDictionary:[HNNotificationUtil propertiesFromUserInfo:userInfo]];
    }
    
    [[HinaDataSDK sharedInstance] track:kHNEventNameNotificationClick withProperties:properties];
}

+ (void)trackEventWithTarget:(NSObject *)target application:(UIApplication *)application localNotification:(UILocalNotification *)notification {
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != application.delegate) {
        return;
    }
    //track notification
    BOOL isValidPushClick = NO;
    if (application.applicationState == UIApplicationStateInactive) {
        isValidPushClick = YES;
    } else if (application.hinadata_launchOptions[UIApplicationLaunchOptionsLocalNotificationKey]) {
        isValidPushClick = YES;
        application.hinadata_launchOptions = nil;
    }
    
    if (!isValidPushClick) {
        HNLogInfo(@"Invalid app push callback, AppPushClick was ignored.");
        return;
    }
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    properties[kHNEventPropertyNotificationContent] = notification.alertBody;
    properties[kSFMessageContent] = notification.alertBody;
    properties[kHNEventPropertyNotificationServiceName] = kHNEventPropertyNotificationServiceNameLocal;
    
    if (@available(iOS 8.2, *)) {
        properties[kHNEventPropertyNotificationTitle] = notification.alertTitle;
        properties[kSFMessageTitle] = notification.alertTitle;
    }
    
    [[HinaDataSDK sharedInstance] track:kHNEventNameNotificationClick withProperties:properties];
}

+ (NSSet<NSString *> *)optionalSelectors {
    return [NSSet setWithArray:@[@"application:didReceiveLocalNotification:", @"application:didReceiveRemoteNotification:fetchCompletionHandler:"]];
}

@end
