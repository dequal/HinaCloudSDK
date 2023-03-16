//
// HNApplication.h
// HinaDataSDK
//
// Created by hina on 2022/9/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNApplication : NSObject

+ (id)sharedApplication;
+ (BOOL)isAppExtension;

@end

NS_ASSUME_NONNULL_END
