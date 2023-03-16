//
// UIView+ExposureListener.h
// HinaDataSDK
//
// Created by hina on 2022/8/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (HNExposureListener)

- (void)hinadata_didMoveToSuperview;

/// exposure mark to improve performance on some APIs, such as didMoveToWindow
@property (nonatomic, copy, nullable) NSString *hinadata_exposureMark;

@property (nonatomic, weak, nullable) NSObject *hinadata_exposure_observer;

@end

NS_ASSUME_NONNULL_END
