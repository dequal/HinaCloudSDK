//
// HNEventCallbackInterceptor.h
// HinaDataSDK
//
// Created by hina on 2022/4/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^HNEventCallback)(NSString *event, NSMutableDictionary<NSString *, id> *properties);

@interface HNEventCallbackInterceptor : HNInterceptor

@end

NS_ASSUME_NONNULL_END
