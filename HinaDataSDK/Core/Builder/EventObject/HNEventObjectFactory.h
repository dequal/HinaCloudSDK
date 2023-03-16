//
// HNEventObjectFactory.h
// HinaDataSDK
//
// Created by hina on 2022/4/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNBaseEventObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNEventObjectFactory : NSObject

+ (HNBaseEventObject *)eventObjectWithH5Event:(NSDictionary *)event;

@end

NS_ASSUME_NONNULL_END
