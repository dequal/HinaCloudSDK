//
// UNUserNotificationCenter+HNPushClick.m
// HinaDataSDK
//
// Created by hina on 2022/1/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UNUserNotificationCenter+HNPushClick.h"
#import "HNUNUserNotificationCenterDelegateProxy.h"

@implementation UNUserNotificationCenter (PushClick)

- (void)hinadata_setDelegate:(id<UNUserNotificationCenterDelegate>)delegate {
    //resolve optional selectors
    [HNUNUserNotificationCenterDelegateProxy resolveOptionalSelectorsForDelegate:delegate];
    
    [self hinadata_setDelegate:delegate];
    if (!self.delegate) {
        return;
    }
    [HNUNUserNotificationCenterDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:"]]];
}

@end
