//
// HNTaskObject.h
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNNodeObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNTaskObject : NSObject

@property (nonatomic, copy) NSString *taskID;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDictionary<NSString *, id> *param;

@property (nonatomic, strong) NSArray<NSString *> *nodeIDs;

@property (nonatomic, strong) NSMutableArray<HNNodeObject *> *nodes;

- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dic;
- (instancetype)initWithTaskID:(NSString *)taskID name:(NSString *)name nodes:(NSArray<HNNodeObject *> *)nodes;

/// 在任务重查询节点位置
///
/// 如果结果小于 0，则任务重不包含该节点
/// 
/// @param nodeID 节点 Id
/// @return 返回位置
- (NSInteger)indexOfNodeWithID:(NSString *)nodeID;

/// 任务中插入节点
///
/// 需要在 start flow 前插入，否则可能无效
/// 
/// @param node 需要插入的节点
/// @param index 插入位置
- (void)insertNode:(HNNodeObject *)node atIndex:(NSUInteger)index;

+ (NSDictionary<NSString *, HNTaskObject *> *)loadFromBundle:(NSBundle *)bundle;

@end

NS_ASSUME_NONNULL_END
