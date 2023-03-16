//
// HNGestureTarget.m
// HinaDataSDK
//
// Created by hina on 2022/2/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNGestureTarget.h"
#import "HNGestureViewProcessorFactory.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"
#import "UIView+HNAutoTrack.h"
#import "HNAutoTrackUtils.h"
#import "HNAutoTrackManager.h"

@implementation HNGestureTarget

+ (HNGestureTarget * _Nullable)targetWithGesture:(UIGestureRecognizer *)gesture {
    NSString *gestureType = NSStringFromClass(gesture.class);
    if ([gesture isMemberOfClass:UITapGestureRecognizer.class] ||
        [gesture isMemberOfClass:UILongPressGestureRecognizer.class] ||
        [gestureType isEqualToString:@"_UIContextMenuSelectionGestureRecognizer"]) {
        return [[HNGestureTarget alloc] init];
    }
    return nil;
}

- (void)trackGestureRecognizerAppClick:(UIGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded &&
        gesture.state != UIGestureRecognizerStateCancelled) {
        return;
    }
    HNGeneralGestureViewProcessor *processor = [HNGestureViewProcessorFactory processorWithGesture:gesture];
    if (!processor.isTrackable) {
        return;
    }

    [HNAutoTrackManager.defaultManager.appClickTracker autoTrackEventWithGestureView:processor.trackableView];
}

@end
