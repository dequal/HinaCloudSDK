//
// HNVisualizedAbstractMessage.h
// HinaDataSDK
//
// Created by hina on 2022/9/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

#import "HNVisualizedMessage.h"

@interface HNVisualizedAbstractMessage : NSObject <HNVisualizedMessage>

@property (nonatomic, copy, readonly) NSString *type;

+ (instancetype)messageWithType:(NSString *)type payload:(NSDictionary *)payload;

- (instancetype)initWithType:(NSString *)type;
- (instancetype)initWithType:(NSString *)type payload:(NSDictionary *)payload;

- (void)setPayloadObject:(id)object forKey:(NSString *)key;
- (id)payloadObjectForKey:(NSString *)key;
- (void)removePayloadObjectForKey:(NSString *)key;
- (NSDictionary *)payload;

- (NSData *)JSONDataWithFeatureCode:(NSString *)featureCode;

@end
