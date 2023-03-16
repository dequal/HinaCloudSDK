//
// HNViewElementInfo.h
// HinaDataSDK
//
// Created by hina on 2022/2/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import "HNAutoTrackProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNViewElementInfo : NSObject

@property (nonatomic, weak) UIView *view;

- (instancetype)initWithView:(UIView *)view;

- (NSString *)elementType;

- (BOOL)isSupportElementPosition;

- (BOOL)isVisualView;

@end

@interface HNAlertElementInfo : HNViewElementInfo
@end

@interface HNMenuElementInfo : HNViewElementInfo
@end

NS_ASSUME_NONNULL_END
