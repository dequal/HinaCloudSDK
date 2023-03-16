//
// HNObject+HNConfigOptions.h
// HinaDataSDK
//
// Created by hina on 2022/6/30.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNDatabase.h"
#import "HNConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNDatabase (HNConfigOptions)

@property (nonatomic, assign, readonly) NSUInteger maxCacheSize;

@end

NS_ASSUME_NONNULL_END
