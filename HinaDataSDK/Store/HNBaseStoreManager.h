//
// HNBaseStoreManager.h
// HinaDataSDK
//
// Created by hina on 2022/12/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNStorePlugin.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^HNStoreManagerCompletion)(id _Nullable object);

@interface HNBaseStoreManager : NSObject

- (void)registerStorePlugin:(id<HNStorePlugin>)plugin;

#pragma mark - get

- (nullable id)objectForKey:(NSString *)key;
- (void)objectForKey:(NSString *)key completion:(HNStoreManagerCompletion)completion;

- (nullable NSString *)stringForKey:(NSString *)key;
- (nullable NSArray *)arrayForKey:(NSString *)key;
- (nullable NSDictionary *)dictionaryForKey:(NSString *)key;
- (nullable NSData *)dataForKey:(NSString *)key;
- (NSInteger)integerForKey:(NSString *)key;
- (float)floatForKey:(NSString *)key;
- (double)doubleForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;

#pragma mark - set

- (void)setObject:(nullable id)object forKey:(NSString *)key;

- (void)setInteger:(NSInteger)value forKey:(NSString *)key;
- (void)setFloat:(float)value forKey:(NSString *)key;
- (void)setDouble:(double)value forKey:(NSString *)key;
- (void)setBool:(BOOL)value forKey:(NSString *)key;

#pragma mark - remove

- (void)removeObjectForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
