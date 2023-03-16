//
// HNItemEventObject.h
// HinaDataSDK
//
// Created by hina on 2022/11/3.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNBaseEventObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNItemEventObject : HNBaseEventObject

@property (nonatomic, copy, nullable) NSString *itemType;
@property (nonatomic, copy, nullable) NSString *itemID;

- (instancetype)initWithType:(NSString *)type itemType:(NSString *)itemType itemID:(NSString *)itemID;

@end

NS_ASSUME_NONNULL_END
