//
// HNNetworkInfoPropertyPlugin.h
// HinaDataSDK
//
// Created by hina on 2022/3/11.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNPropertyPlugin.h"
#import "HNConstants+Private.h"

NS_ASSUME_NONNULL_BEGIN


/// 网络相关属性
@interface HNNetworkInfoPropertyPlugin : HNPropertyPlugin

/// 当前的网络类型 (NS_OPTIONS)
/// @return 网络类型
- (HinaDataNetworkType)currentNetworkTypeOptions;

/// 当前网络类型 (String)
/// @return 网络类型
- (NSString *)networkTypeString;

@end

NS_ASSUME_NONNULL_END
