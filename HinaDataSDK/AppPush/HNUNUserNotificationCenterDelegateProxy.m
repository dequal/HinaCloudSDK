//
// HNUNUserNotificationCenterDelegateProxy.m
// HinaDataSDK
//
// Created by hina on 2022/1/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNUNUserNotificationCenterDelegateProxy.h"
#import "HNClassHelper.h"
#import "NSObject+HNDelegateProxy.h"
#import "HNAppPushConstants.h"
#import "HinaDataSDK.h"
#import "HNLog.h"
#import "HNNotificationUtil.h"
#import <objc/message.h>

@implementation HNUNUserNotificationCenterDelegateProxy

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler  API_AVAILABLE(ios(10.0)){
    SEL selector = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
    [HNUNUserNotificationCenterDelegateProxy invokeWithTarget:self selector:selector, center, response, completionHandler];
    [HNUNUserNotificationCenterDelegateProxy trackEventWithTarget:self notificationCenter:center notificationResponse:response];
}

+ (void)trackEventWithTarget:(NSObject *)target notificationCenter:(UNUserNotificationCenter *)center notificationResponse:(UNNotificationResponse *)response  API_AVAILABLE(ios(10.0)){
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != center.delegate) {
        return;
    }
    //track notification
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    UNNotificationRequest *request = response.notification.request;
    BOOL isRemoteNotification = [request.trigger isKindOfClass:[UNPushNotificationTrigger class]];
    if (isRemoteNotification) {
        properties[kHNEventPropertyNotificationChannel] = kHNEventPropertyNotificationChannelApple;
    } else {
        properties[kHNEventPropertyNotificationServiceName] = kHNEventPropertyNotificationServiceNameLocal;
    }
    
    properties[kHNEventPropertyNotificationTitle] = request.content.title;
    properties[kHNEventPropertyNotificationContent] = request.content.body;
    
    NSDictionary *userInfo = request.content.userInfo;
    if (userInfo) {
        [properties addEntriesFromDictionary:[HNNotificationUtil propertiesFromUserInfo:userInfo]];
        if (userInfo[kHNPushServiceKeySF]) {
            properties[kSFMessageTitle] = request.content.title;
            properties[kSFMessageContent] = request.content.body;
        }
    }
    
    [[HinaDataSDK sharedInstance] track:kHNEventNameNotificationClick withProperties:properties];
}

+ (NSSet<NSString *> *)optionalSelectors {
    return [NSSet setWithArray:@[@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"]];
}

@end
