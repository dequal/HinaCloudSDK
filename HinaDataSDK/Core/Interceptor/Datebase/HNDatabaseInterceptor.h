//
// HNDatabaseInterceptor.h
// HinaDataSDK
//
// Created by  hina on 2022/5/17.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNInterceptor.h"
#import "HNEventStore.h"
#import "HNBaseEventObject.h"

NS_ASSUME_NONNULL_BEGIN

/// 数据库记录操作拦截器基类
@interface HNDatabaseInterceptor : HNInterceptor

@property (nonatomic, strong, readonly) HNEventStore *eventStore;


@end

NS_ASSUME_NONNULL_END
