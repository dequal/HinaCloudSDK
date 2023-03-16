//
// UIView+HNRNView.m
// HinaDataSDK
//
// Created by hina on 2022/8/31.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HNRNView.h"

@implementation UIView (HNRNView)

- (BOOL)isHinadataRNView {
    UIView *view = self;
    NSString *className = NSStringFromClass(view.class);
    if ([className isEqualToString:@"UISegment"]) {
        // 针对 UISegment，可能是 RCTSegmentedControl 或 RNCSegmentedControl 内嵌元素，使用父视图判断是否为 RN 元素
        view = [view superview];
    }
    NSArray <NSString *> *classNames = @[@"RCTSurfaceView", @"RCTSurfaceHostingView", @"RCTFPSGraph", @"RCTModalHostView", @"RCTView", @"RCTTextView", @"RCTRootView",  @"RCTInputAccessoryView", @"RCTInputAccessoryViewContent", @"RNSScreenContainerView", @"RNSScreen", @"RCTVideo", @"RCTSwitch", @"RCTSlider", @"RCTSegmentedControl", @"RNGestureHandlerButton", @"RNCSlider", @"RNCSegmentedControl"];
    for (NSString *className in classNames) {
        Class class = NSClassFromString(className);
        if (class && [view isKindOfClass:class]) {
            return YES;
        }
    }
    return NO;
}

@end
