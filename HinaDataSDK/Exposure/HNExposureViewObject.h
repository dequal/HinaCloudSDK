//
// HNExposureView.h
// HinaDataSDK
//
// Created by hina on 2022/8/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import "HNExposureData.h"
#import "HNExposureTimer.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HNExposureViewState) {
    HNExposureViewStateVisible,
    HNExposureViewStateInvisible,
    HNExposureViewStateBackgroundInvisible,
    HNExposureViewStateExposing,
};

typedef NS_ENUM(NSUInteger, HNExposureViewType) {
    HNExposureViewTypeNormal,
    HNExposureViewTypeCell,
};

@interface HNExposureViewObject : NSObject

@property (nonatomic, weak) UIView *view;
@property (nonatomic, assign) HNExposureViewState state;
@property (nonatomic, assign) HNExposureViewType type;
@property (nonatomic, strong) HNExposureData *exposureData;
@property (nonatomic, weak, readonly) UIViewController *viewController;
@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, assign) NSTimeInterval lastExposure;
@property (nonatomic, assign) CGFloat lastAreaRate;
@property (nonatomic, strong) HNExposureTimer *timer;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithView:(UIView *)view exposureData:(HNExposureData *)exposureData;

- (void)addExposureViewObserver;
- (void)clear;
- (void)exposureConditionCheck;

@end

NS_ASSUME_NONNULL_END
