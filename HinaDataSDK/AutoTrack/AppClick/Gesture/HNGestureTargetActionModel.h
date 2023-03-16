//
// HNGestureTargetActionModel.h
// HinaDataSDK
//
// Created by hina on 2022/2/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNGestureTargetActionModel : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, assign, readonly) BOOL isValid;

- (instancetype)initWithTarget:(id)target action:(SEL)action;
- (BOOL)isEqualToTarget:(id)target andAction:(SEL)action;

/// 查询数组中是否存在一个对象的 target-action 和 参数的 target-action 相同
/// 由于在 dealloc 中使用了 weak 引用,会触发崩溃,因此没有通过重写 isEqual: 方式实现该逻辑
/// @param target target
/// @param action action
/// @param models 待查询的数组
+ (HNGestureTargetActionModel * _Nullable)containsObjectWithTarget:(id)target andAction:(SEL)action fromModels:(NSArray <HNGestureTargetActionModel *>*)models;

/// 从数组中过滤出有效的 target-action 对象
/// @param models 有效的对象数组
+ (NSArray <HNGestureTargetActionModel *>*)filterValidModelsFrom:(NSArray <HNGestureTargetActionModel *>*)models;

@end

NS_ASSUME_NONNULL_END
