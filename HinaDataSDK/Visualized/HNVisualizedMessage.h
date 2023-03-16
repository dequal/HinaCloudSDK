//
// HNVisualizedMessage.h
// HinaDataSDK
//
// Created by hina on 2022/9/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

@class HNVisualizedConnection;

@protocol HNVisualizedMessage <NSObject>

@property (nonatomic, copy, readonly) NSString *type;

- (void)setPayloadObject:(id)object forKey:(NSString *)key;

- (id)payloadObjectForKey:(NSString *)key;

- (void)removePayloadObjectForKey:(NSString *)key;

- (NSData *)JSONDataWithFeatureCode:(NSString *)featureCode;

@optional
- (NSOperation *)responseCommandWithConnection:(HNVisualizedConnection *)connection;

@end
