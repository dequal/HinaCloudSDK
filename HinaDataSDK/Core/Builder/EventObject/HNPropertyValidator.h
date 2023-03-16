//
// HNPropertyValidator.h
// HinaDataSDK
//
// Created by hina on 2022/4/12.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNValidator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HNPropertyKeyProtocol <NSObject>

- (void)hinadata_isValidPropertyKeyWithError:(NSError **)error;

@end

@protocol HNPropertyValueProtocol <NSObject>

- (id _Nullable)hinadata_propertyValueWithKey:(NSString *)key error:(NSError **)error;

@end

@protocol HNEventPropertyValidatorProtocol <NSObject>

- (id _Nullable)hinadata_validKey:(NSString *)key value:(id)value error:(NSError **)error;

@end

@interface NSString (HNProperty)<HNPropertyKeyProtocol, HNPropertyValueProtocol>
@end

@interface NSNumber (HNProperty)<HNPropertyValueProtocol>
@end

@interface NSDate (HNProperty)<HNPropertyValueProtocol>
@end

@interface NSSet (HNProperty)<HNPropertyValueProtocol>
@end

@interface NSArray (HNProperty)<HNPropertyValueProtocol>
@end

@interface NSNull (HNProperty)<HNPropertyValueProtocol>
@end

@interface NSDictionary (HNProperty) <HNEventPropertyValidatorProtocol>
@end

@interface HNPropertyValidator : NSObject

+ (NSMutableDictionary *)validProperties:(NSDictionary *)properties;
+ (NSMutableDictionary *)validProperties:(NSDictionary *)properties validator:(id<HNEventPropertyValidatorProtocol>)validator;

@end

NS_ASSUME_NONNULL_END
