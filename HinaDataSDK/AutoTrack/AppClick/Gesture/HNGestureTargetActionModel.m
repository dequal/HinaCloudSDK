//
// HNGestureTargetActionModel.m
// HinaDataSDK
//
// Created by hina on 2022/2/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNGestureTargetActionModel.h"

@implementation HNGestureTargetActionModel

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    if (self = [super init]) {
        self.target = target;
        self.action = action;
    }
    return self;
}

- (BOOL)isEqualToTarget:(id)target andAction:(SEL)action {
    return (self.target == target) && [NSStringFromSelector(self.action) isEqualToString:NSStringFromSelector(action)];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"target = %@; action = %@; description = %@", self.target, NSStringFromSelector(self.action), [super description]];
}

- (BOOL)isValid {
    return [self.target respondsToSelector:self.action];
}

+ (HNGestureTargetActionModel * _Nullable)containsObjectWithTarget:(id)target andAction:(SEL)action fromModels:(NSArray <HNGestureTargetActionModel *>*)models {
    for (HNGestureTargetActionModel *model in models) {
        if ([model isEqualToTarget:target andAction:action]) {
            return model;
        }
    }
    return nil;
}

+ (NSArray <HNGestureTargetActionModel *>*)filterValidModelsFrom:(NSArray <HNGestureTargetActionModel *>*)models {
    NSMutableArray *result = [NSMutableArray array];
    for (HNGestureTargetActionModel *model in models) {
        if (model.isValid) {
            [result addObject:model];
        }
    }
    return [result copy];
}

@end
