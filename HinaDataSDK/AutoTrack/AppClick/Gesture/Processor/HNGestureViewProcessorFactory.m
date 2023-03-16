//
// HNGestureViewProcessorFactory.m
// HinaDataSDK
//
// Created by hina on 2022/2/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNGestureViewProcessorFactory.h"

@implementation HNGestureViewProcessorFactory

+ (HNGeneralGestureViewProcessor *)processorWithGesture:(UIGestureRecognizer *)gesture {
    NSString *viewType = NSStringFromClass(gesture.view.class);
    if ([viewType isEqualToString:@"_UIAlertControllerView"]) {
        return [[HNLegacyAlertGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([viewType isEqualToString:@"_UIAlertControllerInterfaceActionGroupView"]) {
        return [[HNNewAlertGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([viewType isEqualToString:@"UIInterfaceActionGroupView"]) {
        return [[HNLegacyMenuGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([viewType isEqualToString:@"_UIContextMenuActionsListView"]) {
        return [[HNMenuGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([viewType isEqualToString:@"UITableViewCellContentView"]) {
        return [[HNTableCellGestureViewProcessor alloc] initWithGesture:gesture];
    }
    if ([gesture.view.nextResponder isKindOfClass:UICollectionViewCell.class]) {
        return [[HNCollectionCellGestureViewProcessor alloc] initWithGesture:gesture];
    }
    return [[HNGeneralGestureViewProcessor alloc] initWithGesture:gesture];
}

@end
