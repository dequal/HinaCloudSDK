//
// HNPropertyPlugin+HNPrivate.h
// HinaDataSDK
//
// Created by hina on 2022/4/24.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNPropertyPlugin ()

@property (nonatomic, strong, nullable) id<HNPropertyPluginEventFilter> filter;

@property (nonatomic, copy) NSDictionary<NSString *, id> *properties;
@property (nonatomic, copy) HNPropertyPluginHandler handler;

@end

NS_ASSUME_NONNULL_END
