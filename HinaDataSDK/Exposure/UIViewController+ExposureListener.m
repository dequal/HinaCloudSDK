//
// UIViewController+ExposureListener.m
// HinaDataSDK
//
// Created by hina on 2022/8/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIViewController+ExposureListener.h"
#import "HNExposureViewObject.h"
#import "HNExposureManager.h"

@implementation UIViewController (HNExposureListener)

- (void)hinadata_exposure_viewDidAppear:(BOOL)animated {
    [self hinadata_exposure_viewDidAppear:animated];

    for (HNExposureViewObject *exposureViewObject in [HNExposureManager defaultManager].exposureViewObjects) {
        if (exposureViewObject.viewController == self) {
            [exposureViewObject exposureConditionCheck];
        }
    }
}

-(void)hinadata_exposure_viewDidDisappear:(BOOL)animated {
    [self hinadata_exposure_viewDidDisappear:animated];

    for (HNExposureViewObject *exposureViewObject in [HNExposureManager defaultManager].exposureViewObjects) {
        if (exposureViewObject.viewController == self) {
            exposureViewObject.state = HNExposureViewStateInvisible;
            exposureViewObject.lastExposure = 0;
            [exposureViewObject.timer stop];
        }
    }
}

@end
