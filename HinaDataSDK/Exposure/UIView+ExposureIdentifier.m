//
// UIView+ExposureIdentifier.m
// HinaDataSDK
//
// Created by hina on 2022/8/22.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+ExposureIdentifier.h"
#import <objc/runtime.h>

static void *const kHNUIViewExposureIdentifierKey = (void *)&kHNUIViewExposureIdentifierKey;

@implementation UIView (HNExposureIdentifier)

- (NSString *)exposureIdentifier {
    return objc_getAssociatedObject(self, kHNUIViewExposureIdentifierKey);
}

- (void)setExposureIdentifier:(NSString *)exposureIdentifier {
    objc_setAssociatedObject(self, kHNUIViewExposureIdentifierKey, exposureIdentifier, OBJC_ASSOCIATION_COPY);
}



@end
