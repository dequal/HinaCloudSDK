//
// HNApplicationStateSerializer.h
// HinaDataSDK
//
// Created by hina on 1/18/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <UIKit/UIKit.h>

@class HNObjectSerializerConfig;
@class HNObjectIdentityProvider;

@interface HNApplicationStateSerializer : NSObject

- (instancetype)initWithConfiguration:(HNObjectSerializerConfig *)configuration
             objectIdentityProvider:(HNObjectIdentityProvider *)objectIdentityProvider;

/// 所有 window 截图合成
- (void)screenshotImageForAllWindowWithCompletionHandler:(void(^)(UIImage *))completionHandler;

- (NSDictionary *)objectHierarchyForRootObject;

@end
