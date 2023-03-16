//
// HNNodeObject.h
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNInterceptor.h"
#import "HNFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNNodeObject : NSObject

@property (nonatomic, copy) NSString *nodeID;
@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *interceptorClassName;
@property (nonatomic, strong) NSDictionary<NSString *, id> *param;

- (instancetype)initWithDictionary:(NSDictionary<NSString *, id> *)dic;
- (instancetype)initWithNodeID:(NSString *)nodeID name:(NSString *)name interceptor:(HNInterceptor *)interceptor;

@property (nonatomic, strong, readonly) HNInterceptor *interceptor;

+ (NSDictionary<NSString *, HNNodeObject *> *)loadFromBundle:(NSBundle *)bundle;

@end

NS_ASSUME_NONNULL_END
