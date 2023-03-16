//
// HNViewElementInfoFactory.m
// HinaDataSDK
//
// Created by hina on 2022/2/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNViewElementInfoFactory.h"

@implementation HNViewElementInfoFactory

+ (HNViewElementInfo *)elementInfoWithView:(UIView *)view {
    NSString *viewType = NSStringFromClass(view.class);
    if ([viewType isEqualToString:@"_UIInterfaceActionCustomViewRepresentationView"] ||
        [viewType isEqualToString:@"_UIAlertControllerCollectionViewCell"]) {
        return [[HNAlertElementInfo alloc] initWithView:view];
    }
    
    // _UIContextMenuActionView 为 iOS 13 UIMenu 最终响应事件的控件类型;
    // _UIContextMenuActionsListCell 为 iOS 14 UIMenu 最终响应事件的控件类型;
    if ([viewType isEqualToString:@"_UIContextMenuActionView"] ||
        [viewType isEqualToString:@"_UIContextMenuActionsListCell"]) {
        return [[HNMenuElementInfo alloc] initWithView:view];
    }
    return [[HNViewElementInfo alloc] initWithView:view];
}

@end
