//
// HNViewElementInfo.m
// HinaDataSDK
//
// Created by hina on 2022/2/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNViewElementInfo.h"
#import "HNAutoTrackManager.h"

#pragma mark - View Element Type
@implementation HNViewElementInfo

- (instancetype)initWithView:(UIView *)view {
    if (self = [super init]) {
        self.view = view;
    }
    return self;
}

- (NSString *)elementType {
    return NSStringFromClass(self.view.class);
}

- (BOOL)isSupportElementPosition {
    return YES;
}

- (BOOL)isVisualView {
    if (!self.view.userInteractionEnabled || self.view.alpha <= 0.01 || self.view.isHidden) {
        return NO;
    }
    return [HNAutoTrackManager.defaultManager isGestureVisualView:self.view];
}

@end

#pragma mark - Alert Element Type
@implementation HNAlertElementInfo

- (NSString *)elementType {
    UIWindow *window = self.view.window;
    if ([NSStringFromClass(window.class) isEqualToString:@"_UIAlertControllerShimPresenterWindow"]) {
        CGFloat actionHeight = self.view.bounds.size.height;
        if (actionHeight > 50) {
            return NSStringFromClass(UIActionSheet.class);
        } else {
            return NSStringFromClass(UIAlertView.class);
        }
    } else {
        return NSStringFromClass(UIAlertController.class);
    }
}

- (BOOL)isSupportElementPosition {
    return NO;
}

- (BOOL)isVisualView {
    return YES;
}

@end

#pragma mark - Menu Element Type
@implementation HNMenuElementInfo

- (NSString *)elementType {
    return @"UIMenu";
}

- (BOOL)isSupportElementPosition {
    return NO;
}

- (BOOL)isVisualView {
    // 在 iOS 14 中, 应当圈选 UICollectionViewCell
    if ([self.view.superview isKindOfClass:UICollectionViewCell.class]) {
        return NO;
    }
    return YES;
}

@end
