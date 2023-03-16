//
// UIViewController+ExposureListener.m
// HinaCloudSDK
//
// Created by 陈玉国 on 2022/8/10.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIViewController+ExposureListener.h"
#import "SAExposureViewObject.h"
#import "SAExposureManager.h"

@implementation UIViewController (SAExposureListener)

- (void)sensorsdata_exposure_viewDidAppear:(BOOL)animated {
    [self sensorsdata_exposure_viewDidAppear:animated];

    for (SAExposureViewObject *exposureViewObject in [SAExposureManager defaultManager].exposureViewObjects) {
        if (exposureViewObject.viewController == self) {
            [exposureViewObject exposureConditionCheck];
        }
    }
}

-(void)sensorsdata_exposure_viewDidDisappear:(BOOL)animated {
    [self sensorsdata_exposure_viewDidDisappear:animated];

    for (SAExposureViewObject *exposureViewObject in [SAExposureManager defaultManager].exposureViewObjects) {
        if (exposureViewObject.viewController == self) {
            exposureViewObject.state = SAExposureViewStateInvisible;
            exposureViewObject.lastExposure = 0;
            [exposureViewObject.timer stop];
        }
    }
}

@end
