//
// UIGestureRecognizer+HNAutoTrack.h
// HinaDataSDK
//
// Created by hina on 2022/10/25.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <UIKit/UIKit.h>
#import "HNAutoTrackProperty.h"
#import "HNGestureTarget.h"
#import "HNGestureTargetActionModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIGestureRecognizer (HNAutoTrack)

@property (nonatomic, strong, readonly) NSMutableArray <HNGestureTargetActionModel *>*hinadata_targetActionModels;
@property (nonatomic, strong, readonly) HNGestureTarget *hinadata_gestureTarget;

- (instancetype)hinadata_initWithTarget:(id)target action:(SEL)action;
- (void)hinadata_addTarget:(id)target action:(SEL)action;
- (void)hinadata_removeTarget:(id)target action:(SEL)action;

@end

NS_ASSUME_NONNULL_END
