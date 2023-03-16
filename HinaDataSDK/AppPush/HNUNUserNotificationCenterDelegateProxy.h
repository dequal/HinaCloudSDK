//
// HNUNUserNotificationCenterDelegateProxy.h
// HinaDataSDK
//
// Created by hina on 2022/1/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNDelegateProxy.h"

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
#import <UserNotifications/UserNotifications.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface HNUNUserNotificationCenterDelegateProxy : HNDelegateProxy



@end

NS_ASSUME_NONNULL_END
