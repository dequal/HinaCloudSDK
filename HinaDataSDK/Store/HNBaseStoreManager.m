//
// HNBaseStoreManager.m
// HinaDataSDK
//
// Created by hina on 2022/12/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNBaseStoreManager.h"

static const char * kHNSerialQueueLabel = "com.hinadata.serialQueue.StoreManager";

@interface HNBaseStoreManager ()

@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;

@property (nonatomic, strong) NSMutableArray<id<HNStorePlugin>> *plugins;

@end

@implementation HNBaseStoreManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _plugins = [NSMutableArray array];
    }
    return self;
}

- (dispatch_queue_t)serialQueue {
    static dispatch_once_t onceToken;
    static dispatch_queue_t serialQueue;
    dispatch_once(&onceToken, ^{
        serialQueue = dispatch_queue_create(kHNSerialQueueLabel, DISPATCH_QUEUE_SERIAL);
    });
    return serialQueue;
}

- (NSString *)storeKeyWithPlugin:(id<HNStorePlugin>)plugin key:(NSString *)key {
    return [NSString stringWithFormat:@"%@%@", plugin.type, key];
}

- (BOOL)isMatchedWithPlugin:(id<HNStorePlugin>)plugin key:(NSString *)key {
    SEL sel = NSSelectorFromString(@"storeKeys");
    if (![plugin respondsToSelector:sel]) {
        return NO;
    }
    NSArray *(*imp)(id, SEL) = (NSArray *(*)(id, SEL))[(NSObject *)plugin methodForSelector:sel];
    NSArray *storeKeys = imp(plugin, sel);
    return [storeKeys containsObject:key];
}

- (BOOL)isRegisteredCustomStorePlugin {
    return NO;
}

- (id)objForKey:(NSString *)key {
    for (NSInteger index = 0; index < self.plugins.count; index++) {
        id<HNStorePlugin> plugin = self.plugins[index];
        NSString *storeKey = [self storeKeyWithPlugin:self.plugins[index] key:key];

        id result = [plugin objectForKey:storeKey];
        if (result) {
            // 当有注册自定义存储插件时，做数据迁移
            if ([self isRegisteredCustomStorePlugin] && index != 0) {
                id<HNStorePlugin> firstPlugin = self.plugins.firstObject;
                NSString *firstKey = [self storeKeyWithPlugin:firstPlugin key:key];
                [firstPlugin setObject:result forKey:firstKey];

                [plugin removeObjectForKey:storeKey];
            }
            return result;
        }
    }
    return nil;
}

#pragma mark - public

- (void)registerStorePlugin:(id<HNStorePlugin>)plugin {
    NSAssert(plugin.type.length > 0, @"The store plugin's type must return a not empty string!");
    dispatch_async(self.serialQueue, ^{
        [self.plugins enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id<HNStorePlugin>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([plugin.type isEqualToString:obj.type]) {
                [self.plugins removeObjectAtIndex:idx];
            } else {
                [plugin upgradeWithOldPlugin:obj];
            }
        }];
        [self.plugins insertObject:plugin atIndex:0];
    });
}

#pragma mark - get

- (id)objectForKey:(NSString *)key {
    const char *chars = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    if (chars && strcmp(chars, kHNSerialQueueLabel) == 0) {
        return [self objForKey:key];
    } else {
        __block id object = nil;
        dispatch_sync(self.serialQueue, ^{
            object = [self objForKey:key];
        });
        return object;
    }
}

- (void)objectForKey:(NSString *)key completion:(HNStoreManagerCompletion)completion {
    dispatch_async(self.serialQueue, ^{
        completion([self objForKey:key]);
    });
}

- (nullable NSString *)stringForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSString.class]) {
        return obj;
    }
    if ([obj isKindOfClass:NSNumber.class]) {
        return [obj stringValue];
    }
    return nil;
}

- (nullable NSArray *)arrayForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSArray.class]) {
        return obj;
    }
    return nil;
}

- (nullable NSDictionary *)dictionaryForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSDictionary.class]) {
        return obj;
    }
    return nil;
}

- (nullable NSData *)dataForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSData.class]) {
        return obj;
    }
    return nil;
}

- (NSInteger)integerForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSNumber.class] || [obj isKindOfClass:NSString.class]) {
        return [obj integerValue];
    }
    return 0;
}

- (float)floatForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSNumber.class] || [obj isKindOfClass:NSString.class]) {
        return [obj floatValue];
    }
    return 0;
}

- (double)doubleForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSNumber.class] || [obj isKindOfClass:NSString.class]) {
        return [obj doubleValue];
    }
    return 0;
}

- (BOOL)boolForKey:(NSString *)key {
    id obj = [self objectForKey:key];
    if ([obj isKindOfClass:NSNumber.class] || [obj isKindOfClass:NSString.class]) {
        return [obj boolValue];
    }
    return NO;
}

#pragma mark - set

- (void)setObject:(id)object forKey:(NSString *)key {
    dispatch_async(self.serialQueue, ^{
        if (![self isRegisteredCustomStorePlugin]) {
            for (id<HNStorePlugin> plugin in self.plugins) {
                // 当没有自定义存储插件时，使用插件 key 匹配
                if ([self isMatchedWithPlugin:plugin key:key]) {
                    NSString *storeKey = [self storeKeyWithPlugin:plugin key:key];
                    return [plugin setObject:object forKey:storeKey];
                }
            }
        }

        id<HNStorePlugin> firstPlugin = self.plugins.firstObject;
        NSString *storeKey = [self storeKeyWithPlugin:firstPlugin key:key];
        [firstPlugin setObject:object forKey:storeKey];

        [self.plugins enumerateObjectsUsingBlock:^(id<HNStorePlugin>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx == 0) {
                return;
            }
            [obj removeObjectForKey:[self storeKeyWithPlugin:obj key:key]];
        }];
    });
}

- (void)setInteger:(NSInteger)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)setFloat:(float)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)setDouble:(double)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

- (void)setBool:(BOOL)value forKey:(NSString *)key {
    [self setObject:@(value) forKey:key];
}

#pragma mark - remove

- (void)removeObjectForKey:(NSString *)key {
    dispatch_async(self.serialQueue, ^{
        for (id<HNStorePlugin> obj in self.plugins) {
            [obj removeObjectForKey:[self storeKeyWithPlugin:obj key:key]];
        }
    });
}

@end
