//
// HNPropertyDescription.h
// HinaDataSDK
//
// Created by hina on 1/18/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

@class HNObjectSerializerContext;

@interface HNPropertySelectorParameterDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *type;
// 上传页面属性的 key
@property (nonatomic, readonly) NSString *key;

@end

@interface HNPropertySelectorDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
@property (nonatomic, readonly) NSString *selectorName;
@property (nonatomic, readonly) NSString *returnType;

@end

@interface HNPropertyDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, readonly) BOOL readonly;

@property (nonatomic, readonly) BOOL useKeyValueCoding;

@property (nonatomic, readonly) NSString *name;

// 上传页面属性的 key
@property (nonatomic, readonly) NSString *key;

@property (nonatomic, readonly) HNPropertySelectorDescription *getSelectorDescription;

- (NSValueTransformer *)valueTransformer;

@end
