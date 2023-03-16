//
// HNProfileEventObject.m
// HinaDataSDK
//
// Created by hina on 2022/4/13.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNProfileEventObject.h"
#import "HNConstants+Private.h"

@implementation HNProfileEventObject

- (instancetype)initWithType:(NSString *)type {
    self = [super init];
    if (self) {
        self.type = [HNBaseEventObject eventTypeWithType:type];
    }
    return self;
}

@end

@implementation HNProfileIncrementEventObject

- (id)hinadata_validKey:(NSString *)key value:(id)value error:(NSError *__autoreleasing  _Nullable *)error {
    id newValue = [super hinadata_validKey:key value:value error:error];
    if (![value isKindOfClass:[NSNumber class]]) {
        *error = HNPropertyError(10007, @"%@ profile_increment value must be NSNumber. got: %@ %@", self, [value class], value);
        return nil;
    }
    return newValue;
}

@end

@implementation HNProfileAppendEventObject

- (id)hinadata_validKey:(NSString *)key value:(id)value error:(NSError *__autoreleasing  _Nullable *)error {
    id newValue = [super hinadata_validKey:key value:value error:error];
    if (![newValue isKindOfClass:[NSArray class]] &&
        ![newValue isKindOfClass:[NSSet class]]) {
        *error = HNPropertyError(10006, @"%@ profile_append value must be NSSet, NSArray. got %@ %@", self, [value  class], value);
        return nil;
    }
    return newValue;
}

@end
