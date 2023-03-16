//
// HNSessionPropertyPlugin.h
// HinaDataSDK
//
// Created by  hina on 2022/5/5.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNPropertyPlugin.h"
#import "HNSessionProperty.h"


NS_ASSUME_NONNULL_BEGIN

/// session 采集属性插件
@interface HNSessionPropertyPlugin : HNPropertyPlugin

/// session 采集属性插件初始化
/// @param sessionProperty session 处理
- (instancetype)initWithSessionProperty:(HNSessionProperty *)sessionProperty NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
