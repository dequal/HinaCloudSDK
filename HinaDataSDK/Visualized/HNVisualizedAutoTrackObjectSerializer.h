//
// HNObjectSerializer.h
// HinaDataSDK
//
// Created by hina on 1/18/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

@class HNClassDescription;
@class HNObjectSerializerConfig;
@class HNObjectIdentityProvider;

@interface HNVisualizedAutoTrackObjectSerializer : NSObject

- (instancetype)initWithConfiguration:(HNObjectSerializerConfig *)configuration
               objectIdentityProvider:(HNObjectIdentityProvider *)objectIdentityProvider;

- (NSDictionary *)serializedObjectsWithRootObject:(id)rootObject;

@end
