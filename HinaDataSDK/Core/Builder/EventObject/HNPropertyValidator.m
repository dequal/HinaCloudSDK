//
// HNPropertyValidator.m
// HinaDataSDK
//
// Created by hina on 2022/4/12.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNPropertyValidator.h"
#import "HNConstants+Private.h"
#import "HNDateFormatter.h"
#import "HinaDataSDK+Private.h"
#import "HNLog.h"
#import "NSObject+HNToString.h"

@implementation NSString (HNProperty)

- (void)hinadata_isValidPropertyKeyWithError:(NSError *__autoreleasing  _Nullable *)error {
    [HNValidator validKey:self error:error];
}

- (id)hinadata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    NSUInteger length = [self lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    if (length > kHNPropertyValueMaxLength) {
        HNLogWarn(@"%@'s length is longer than %ld", self, kHNPropertyValueMaxLength);
    }
    return self;
}

@end

@implementation NSNumber (HNProperty)

- (id)hinadata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    return [self isEqualToNumber:NSDecimalNumber.notANumber] || [self isEqualToNumber:@(INFINITY)] ? nil : self;
}

@end

@implementation NSDate (HNProperty)

- (id)hinadata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    return self;
}

@end

@implementation NSSet (HNProperty)

- (id)hinadata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    NSMutableSet *result = [NSMutableSet set];
    for (id element in self) {
        if (![element conformsToProtocol:@protocol(HNPropertyValueProtocol)]) {
            continue;
        }
        id hinaValue = [(id <HNPropertyValueProtocol>)element hinadata_propertyValueWithKey:key error:error];
        hinaValue = [hinaValue hinadata_toString];
        if (hinaValue) {
            [result addObject:hinaValue];
        }
    }
    return [result copy];
}

@end

@implementation NSArray (HNProperty)

- (id)hinadata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    NSMutableArray *result = [NSMutableArray array];
    for (id element in self) {
        if (![element conformsToProtocol:@protocol(HNPropertyValueProtocol)]) {
            continue;
        }
        id hinaValue = [(id <HNPropertyValueProtocol>)element hinadata_propertyValueWithKey:key error:error];
        hinaValue = [hinaValue hinadata_toString];
        if (hinaValue) {
            [result addObject:hinaValue];
        }
    }
    return [result copy];
}

@end

@implementation NSNull (HNProperty)

- (id)hinadata_propertyValueWithKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable *)error {
    return nil;
}

@end

@implementation NSDictionary (HNProperty)

- (id)hinadata_validKey:(NSString *)key value:(id)value error:(NSError *__autoreleasing  _Nullable *)error {
    if (![key conformsToProtocol:@protocol(HNPropertyKeyProtocol)]) {
        *error = HNPropertyError(10004, @"Property Key: %@ must be NSString", key);
        return nil;
    }

    [(id <HNPropertyKeyProtocol>)key hinadata_isValidPropertyKeyWithError:error];
    if (*error && (*error).code != HNValidatorErrorOverflow) {
        return nil;
    }

    if (![value conformsToProtocol:@protocol(HNPropertyValueProtocol)]) {
        *error = HNPropertyError(10005, @"%@ property values must be NSString, NSNumber, NSSet, NSArray or NSDate. got: %@ %@", self, [value class], value);
        return nil;
    }

    // value 转换
    return [(id <HNPropertyValueProtocol>)value hinadata_propertyValueWithKey:key error:error];
}

@end

@implementation HNPropertyValidator

+ (NSMutableDictionary *)validProperties:(NSDictionary *)properties {
    return [self validProperties:properties validator:properties];
}

+ (NSMutableDictionary *)validProperties:(NSDictionary *)properties validator:(id<HNEventPropertyValidatorProtocol>)validator {
    if (![properties isKindOfClass:[NSDictionary class]] || ![validator conformsToProtocol:@protocol(HNEventPropertyValidatorProtocol)]) {
        return nil;
    }
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (id key in properties) {
        NSError *error = nil;
        id value = [validator hinadata_validKey:key value:properties[key] error:&error];
        if (error) {
            HNLogError(@"%@",error.localizedDescription);
        }
        if (value) {
            result[key] = value;
        }
    }
    return result;
}

@end

