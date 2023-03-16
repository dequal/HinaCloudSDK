//
// HNLimitKeyManager.h
// HinaDataSDK
//
// Created by hina on 2022/10/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNLimitKeyManager : NSObject

+ (void)registerLimitKeys:(NSDictionary<HNLimitKey, NSString *> *)keys;

+ (NSString *)idfa;
+ (NSString *)idfv;
+ (NSString *)carrier;

@end

NS_ASSUME_NONNULL_END
