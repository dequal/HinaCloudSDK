//
// UIView+HNElementPath.m
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HNElementPath.h"
#import "HNUIProperties.h"
#import "HNUIInternalProperties.h"
#import "UIView+HNInternalProperties.h"

@implementation UIView (HNElementPath)

- (NSString *)hinadata_elementPath {
    // 处理特殊控件
    // UISegmentedControl 嵌套 UISegment 作为选项单元格，特殊处理
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        UISegmentedControl *segmentedControl = (UISegmentedControl *)[self superview];
        if ([segmentedControl isKindOfClass:UISegmentedControl.class]) {
            return [HNUIProperties elementPathForView:segmentedControl atViewController:segmentedControl.hinadata_viewController];
        }
    }
    // 支持自定义属性，可见元素均上传 elementPath
    return [HNUIProperties elementPathForView:self atViewController:self.hinadata_viewController];
}

@end
