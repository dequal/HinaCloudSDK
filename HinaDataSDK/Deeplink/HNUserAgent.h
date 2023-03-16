//
// HNUserAgent.h
// HinaDataSDK
//
// Created by hina on 2022/8/19.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNUserAgent : NSObject

+ (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion;

@end

NS_ASSUME_NONNULL_END
