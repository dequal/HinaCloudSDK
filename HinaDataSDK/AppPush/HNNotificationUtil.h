//
// HNNotificationUtil.h
// HinaDataSDK
//
// Created by hina on 2022/1/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNNotificationUtil : NSObject

+ (NSDictionary *)propertiesFromUserInfo:(NSDictionary *)userInfo;

@end

@interface NSString (SFPushKey)

- (NSString *)hinadata_sfPushKey;

@end

NS_ASSUME_NONNULL_END
