//
// UIViewController+ExposureListener.h
// HinaDataSDK
//
// Created by hina on 2022/8/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (HNExposureListener)

-(void)hinadata_exposure_viewDidAppear:(BOOL)animated;
-(void)hinadata_exposure_viewDidDisappear:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
