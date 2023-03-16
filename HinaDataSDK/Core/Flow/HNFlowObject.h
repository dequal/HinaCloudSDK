//
// HNFlowObject.h
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNTaskObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNFlowObject : NSObject

@property (nonatomic, copy) NSString *flowID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSArray<NSString *> *taskIDs;
@property (nonatomic, strong) NSArray<HNTaskObject *> *tasks;
@property (nonatomic, strong) NSDictionary<NSString *, id> *param;

- (instancetype)initWithFlowID:(NSString *)flowID name:(NSString *)name tasks:(NSArray<HNTaskObject *> *)tasks;
- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dic;

- (nullable HNTaskObject *)taskForID:(NSString *)taskID;

+ (NSDictionary<NSString *, HNFlowObject *> *)loadFromBundle:(NSBundle *)bundle;
@end

NS_ASSUME_NONNULL_END
