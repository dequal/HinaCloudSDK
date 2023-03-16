//
// HNViewNodeFactory.m
// HinaDataSDK
//
// Created by hina on 2022/1/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNViewNodeFactory.h"
#import "HNVisualizedUtils.h"
#import "HNViewNode.h"
#import "UIView+HNRNView.h"

@implementation HNViewNodeFactory

+ (nullable HNViewNode *)viewNodeWithView:(UIView *)view {
    if ([NSStringFromClass(view.class) isEqualToString:@"UISegment"]) {
        return [[HNSegmentNode alloc] initWithView:view];
    } else if ([view isKindOfClass:UISegmentedControl.class]) {
        return [[HNSegmentedControlNode alloc] initWithView:view];
    } else if ([view isKindOfClass:UITableViewHeaderFooterView.class]) {
        return [[HNTableViewHeaderFooterViewNode alloc] initWithView:view];
    } else if ([view isKindOfClass:UITableViewCell.class] || [view isKindOfClass:UICollectionViewCell.class]) {
        return [[HNCellNode alloc] initWithView:view];
    } else if ([NSStringFromClass(view.class) isEqualToString:@"UITabBarButton"]) {
        // UITabBarItem 点击事件，支持限定元素位置
        return [[HNTabBarButtonNode alloc] initWithView:view];
    } else if ([view isHinadataRNView]) {
        return [[HNRNViewNode alloc] initWithView:view];
    } else if ([view isKindOfClass:WKWebView.class]) {
        return [[HNWKWebViewNode alloc] initWithView:view];
    } else if ([HNVisualizedUtils isIgnoredItemPathWithView:view]) {
        /* 忽略路径
         1. UITableViewWrapperView 为 iOS11 以下 UITableView 与 cell 之间的 view
         
         2. _UITextFieldCanvasView 和 _UISearchBarFieldEditor 都是 UISearchBar 内部私有 view
         在输入状态下层级关系为：  ...UISearchBarTextField/_UISearchBarFieldEditor/_UITextFieldCanvasView
         非输入状态下层级关系为： .../UISearchBarTextField/_UITextFieldCanvasView
         并且 _UITextFieldCanvasView 是个私有 view,无法获取元素内容。_UISearchBarFieldEditor 是私有 UITextField，可以获取内容
         不论是否输入都准确标识，为方便路径统一，所以忽略 _UISearchBarFieldEditor 路径
         
         3.  UIFieldEditor 是 UITextField 内，只有编辑状态才包含的一层 view，路径忽略，方便统一（自定义属性一般圈选的为 _UITextFieldCanvasView）
         */
        return [[HNIgnorePathNode alloc] initWithView:view];
    } else {
        return [[HNViewNode alloc] initWithView:view];
    }
}

@end
