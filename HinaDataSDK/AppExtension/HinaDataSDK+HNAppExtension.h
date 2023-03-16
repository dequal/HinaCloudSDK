//
// HinaDataSDK+HNAppExtension.h
// HinaDataSDK
//
// Created by hina on 2022/5/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HinaDataSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface HinaDataSDK (HNAppExtension)

/**
 @abstract
 * Track App Extension groupIdentifier 中缓存的数据
 *
 * @param groupIdentifier groupIdentifier
 * @param completion  完成 track 后的 callback
 */
- (void)trackEventFromExtensionWithGroupIdentifier:(NSString *)groupIdentifier completion:(void (^)(NSString *groupIdentifier, NSArray *events)) completion;

@end

NS_ASSUME_NONNULL_END
