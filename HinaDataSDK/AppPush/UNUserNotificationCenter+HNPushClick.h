//
// UNUserNotificationCenter+HNPushClick.h
// HinaDataSDK
//
// Created by hina on 2022/1/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface UNUserNotificationCenter (PushClick)

- (void)hinadata_setDelegate:(id <UNUserNotificationCenterDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
