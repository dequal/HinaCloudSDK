//
// HNIDFAHelper.h
// HinaDataSDK
//
// Created by hina on 2022/12/1.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNIDFAHelper : NSObject

/**
 获取设备的 IDFA

 @return idfa
 */
+ (nullable NSString *)idfa;

@end

NS_ASSUME_NONNULL_END
