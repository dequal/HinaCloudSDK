//
// HNCorrectUserIdInterceptor.h
// HinaABTest
//
// Created by  hina on 2022/6/13.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

/// 修正用户 Id
///
/// 兼容 AB 和 SF SDK 的用户 Id 修正逻辑
@interface HNCorrectUserIdInterceptor : HNInterceptor

@end

NS_ASSUME_NONNULL_END
