//
// UIView+ExposureListener.m
// HinaDataSDK
//
// Created by hina on 2022/8/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+ExposureListener.h"
#import "UIView+ExposureIdentifier.h"
#import "HNExposureManager.h"
#import <objc/runtime.h>

static void *const kHNUIViewExposureMarkKey = (void *)&kHNUIViewExposureMarkKey;
static void *const kHNUIViewExposureObserverKey = (void *)&kHNUIViewExposureObserverKey;

@implementation UIView (HNExposureListener)

- (void)hinadata_didMoveToSuperview {
    [self hinadata_didMoveToSuperview];
    HNExposureViewObject *exposureViewObject = [[HNExposureManager defaultManager] exposureViewWithView:self];
    if (!exposureViewObject) {
        return;
    }
    [exposureViewObject exposureConditionCheck];
}

- (NSString *)hinadata_exposureMark {
    return objc_getAssociatedObject(self, kHNUIViewExposureMarkKey);
}

- (void)setHinadata_exposureMark:(NSString *)hinadata_exposureMark {
    objc_setAssociatedObject(self, kHNUIViewExposureMarkKey, hinadata_exposureMark, OBJC_ASSOCIATION_COPY);
}

- (NSObject *)hinadata_exposure_observer {
    return objc_getAssociatedObject(self, kHNUIViewExposureObserverKey);
}

- (void)setHinadata_exposure_observer:(NSObject *)hinadata_exposure_observer {
    objc_setAssociatedObject(self, kHNUIViewExposureObserverKey, hinadata_exposure_observer, OBJC_ASSOCIATION_RETAIN);
}

@end
