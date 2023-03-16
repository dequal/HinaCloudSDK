//
// HNProfileEventObject.h
// HinaDataSDK
//
// Created by hina on 2022/4/13.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNBaseEventObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNProfileEventObject : HNBaseEventObject

- (instancetype)initWithType:(NSString *)type NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

@interface HNProfileIncrementEventObject : HNProfileEventObject

@end

@interface HNProfileAppendEventObject : HNProfileEventObject

@end

NS_ASSUME_NONNULL_END
