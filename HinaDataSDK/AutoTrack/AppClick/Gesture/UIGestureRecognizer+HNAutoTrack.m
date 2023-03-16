//
// UIGestureRecognizer+HNAutoTrack.m
// HinaDataSDK
//
// Created by hina on 2022/10/25.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIGestureRecognizer+HNAutoTrack.h"
#import <objc/runtime.h>
#import "HNSwizzle.h"
#import "HNLog.h"

static void *const kHNGestureTargetKey = (void *)&kHNGestureTargetKey;
static void *const kHNGestureTargetActionModelsKey = (void *)&kHNGestureTargetActionModelsKey;

@implementation UIGestureRecognizer (HNAutoTrack)

#pragma mark - Hook Method
- (instancetype)hinadata_initWithTarget:(id)target action:(SEL)action {
    [self hinadata_initWithTarget:target action:action];
    [self removeTarget:target action:action];
    [self addTarget:target action:action];
    return self;
}

- (void)hinadata_addTarget:(id)target action:(SEL)action {
    // 在 iOS 12 及以下系统中, 从 StoryBoard 加载的手势不会调用 - initWithTarget:action: 方法;
    // 1. 在 - addTarget:action 时对 hinadata_gestureTarget 和 hinadata_targetActionModels 进行初始化
    // 2. hinadata_gestureTarget 可能会初始化为空值, 因此使用 hinadata_targetActionModels 判断是否初始化过.
    if (!self.hinadata_targetActionModels) {
        self.hinadata_targetActionModels = [NSMutableArray array];
        self.hinadata_gestureTarget = [HNGestureTarget targetWithGesture:self];
    }

    // Track 事件需要在原有事件之前触发(原有事件中更改页面内容,会导致部分内容获取不准确)
    if (self.hinadata_gestureTarget) {
        if (![HNGestureTargetActionModel containsObjectWithTarget:target andAction:action fromModels:self.hinadata_targetActionModels]) {
            HNGestureTargetActionModel *resulatModel = [[HNGestureTargetActionModel alloc] initWithTarget:target action:action];
            [self.hinadata_targetActionModels addObject:resulatModel];
            [self hinadata_addTarget:self.hinadata_gestureTarget action:@selector(trackGestureRecognizerAppClick:)];
        }
    }
    [self hinadata_addTarget:target action:action];
}

- (void)hinadata_removeTarget:(id)target action:(SEL)action {
    if (self.hinadata_gestureTarget) {
        HNGestureTargetActionModel *existModel = [HNGestureTargetActionModel containsObjectWithTarget:target andAction:action fromModels:self.hinadata_targetActionModels];
        if (existModel) {
            [self.hinadata_targetActionModels removeObject:existModel];
        }
    }
    [self hinadata_removeTarget:target action:action];
}

#pragma mark - Associated Object
- (HNGestureTarget *)hinadata_gestureTarget {
    return objc_getAssociatedObject(self, kHNGestureTargetKey);
}

- (void)setHinadata_gestureTarget:(HNGestureTarget *)hinadata_gestureTarget {
    objc_setAssociatedObject(self, kHNGestureTargetKey, hinadata_gestureTarget, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray <HNGestureTargetActionModel *>*)hinadata_targetActionModels {
    return objc_getAssociatedObject(self, kHNGestureTargetActionModelsKey);
}

- (void)setHinadata_targetActionModels:(NSMutableArray <HNGestureTargetActionModel *>*)hinadata_targetActionModels {
    objc_setAssociatedObject(self, kHNGestureTargetActionModelsKey, hinadata_targetActionModels, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
