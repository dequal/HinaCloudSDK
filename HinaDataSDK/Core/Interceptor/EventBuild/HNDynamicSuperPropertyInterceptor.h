//
// HNDynamicSuperPropertyInterceptor.h
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

/// 动态公共属性拦截器
///
/// 动态公共属性需要在 serialQueue 队列外获取，如果外部已采集并进入队列，就不再采集
@interface HNDynamicSuperPropertyInterceptor : HNInterceptor

@end

NS_ASSUME_NONNULL_END
