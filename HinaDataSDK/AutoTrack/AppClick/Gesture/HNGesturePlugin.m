//
// HNGesturePlugin.m
// HinaDataSDK
//
// Created by hina on 2022/11/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNGesturePlugin.h"
#import "HNSwizzle.h"
#import "UIGestureRecognizer+HNAutoTrack.h"
#import <UIKit/UIKit.h>

static NSString *const kHNEventTrackerPluginType = @"AppClick+UIGestureRecognizer";

@implementation HNGesturePlugin

- (void)install {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod];
    });
    self.enable = YES;
}

- (void)uninstall {
    self.enable = NO;
}

- (NSString *)type {
    return kHNEventTrackerPluginType;
}

- (void)swizzleMethod {
    // Gesture
    [UIGestureRecognizer sa_swizzleMethod:@selector(initWithTarget:action:)
                               withMethod:@selector(hinadata_initWithTarget:action:)
                                    error:NULL];
    [UIGestureRecognizer sa_swizzleMethod:@selector(addTarget:action:)
                               withMethod:@selector(hinadata_addTarget:action:)
                                    error:NULL];
    [UIGestureRecognizer sa_swizzleMethod:@selector(removeTarget:action:)
                               withMethod:@selector(hinadata_removeTarget:action:)
                                    error:NULL];
}

@end
