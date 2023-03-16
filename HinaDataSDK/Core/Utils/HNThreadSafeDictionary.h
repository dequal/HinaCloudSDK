//
// HNThreadSafeDictionary.h
// HinaDataSDK
//
// Created by hina on 2022/9/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface HNThreadSafeDictionary<KeyType, ObjectType> : NSObject

+ (HNThreadSafeDictionary *)dictionary;

@property (readonly, copy) NSArray<KeyType> *allKeys;
@property (readonly, copy) NSArray<ObjectType> *allValues;

- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType <NSCopying>)key;

- (void)removeObjectForKey:(KeyType)aKey;
- (void)enumerateKeysAndObjectsUsingBlock:(void (NS_NOESCAPE ^)(KeyType key, ObjectType obj, BOOL *stop))block;

@end

NS_ASSUME_NONNULL_END
