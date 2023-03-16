//
// HNEventIdentifier.h
// HinaDataSDK
//
// Created by hina on 2022/3/23.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNVisualPropertiesConfig.h"
#import "HinaDataSDK+Private.h"

NS_ASSUME_NONNULL_BEGIN

/// 事件标识
@interface HNEventIdentifier : HNViewIdentifier

/// 事件名
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, strong) NSMutableDictionary *properties;

- (instancetype)initWithEventInfo:(NSDictionary *)eventInfo;

@end

NS_ASSUME_NONNULL_END
