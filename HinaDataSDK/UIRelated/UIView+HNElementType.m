//
// UIView+HNElementType.m
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HNElementType.h"

static NSString * const kHNMenuElementType = @"UIMenu";

@implementation UIView (HNElementType)

- (NSString *)hinadata_elementType {
    NSString *viewType = NSStringFromClass(self.class);
    if ([viewType isEqualToString:@"_UIInterfaceActionCustomViewRepresentationView"] ||
        [viewType isEqualToString:@"_UIAlertControllerCollectionViewCell"]) {
        return [self alertElementType];
    }

    // _UIContextMenuActionView 为 iOS 13 UIMenu 最终响应事件的控件类型;
    // _UIContextMenuActionsListCell 为 iOS 14 UIMenu 最终响应事件的控件类型;
    if ([viewType isEqualToString:@"_UIContextMenuActionView"] ||
        [viewType isEqualToString:@"_UIContextMenuActionsListCell"]) {
        return [self menuElementType];
    }
    return viewType;
}

- (NSString *)alertElementType {
    UIWindow *window = self.window;
    if ([NSStringFromClass(window.class) isEqualToString:@"_UIAlertControllerShimPresenterWindow"]) {
        CGFloat actionHeight = self.bounds.size.height;
        if (actionHeight > 50) {
            return NSStringFromClass(UIActionSheet.class);
        } else {
            return NSStringFromClass(UIAlertView.class);
        }
    } else {
        return NSStringFromClass(UIAlertController.class);
    }
}

- (NSString *)menuElementType {
    return kHNMenuElementType;
}

@end
