//
// UIView+HNItemPath.m
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HNItemPath.h"
#import "HNUIProperties.h"
#import "UITableViewCell+HNIndexPath.h"

@implementation UIView (HNItemPath)

- (NSString *)hinadata_itemPath {
    /* 忽略路径
     UITableViewWrapperView 为 iOS11 以下 UITableView 与 cell 之间的 view
     _UITextFieldCanvasView 和 _UISearchBarFieldEditor 都是 UISearchBar 内部私有 view
     在输入状态下  ...UISearchBarTextField/_UISearchBarFieldEditor/_UITextFieldCanvasView/...
     非输入状态下 .../UISearchBarTextField/_UITextFieldCanvasView
     并且 _UITextFieldCanvasView 是个私有 view,无法获取元素内容(目前通过 nextResponder 获取 textField 采集内容)。方便路径统一，所以忽略 _UISearchBarFieldEditor 路径
     */
    if ([HNUIProperties isIgnoredItemPathWithView:self]) {
        return nil;
    }

    NSString *className = NSStringFromClass(self.class);
    NSInteger index = [HNUIProperties indexWithResponder:self];
    if (index < 0) { // -1
        return className;
    }
    return [NSString stringWithFormat:@"%@[%ld]", className, (long)index];
}

@end

@implementation UISegmentedControl (HNItemPath)

- (NSString *)hinadata_itemPath {
    // 支持单个 UISegment 创建事件。UISegment 是 UIImageView 的私有子类，表示UISegmentedControl 单个选项的显示区域
    NSString *subPath = [NSString stringWithFormat:@"UISegment[%ld]", (long)self.selectedSegmentIndex];
    return [NSString stringWithFormat:@"%@/%@", super.hinadata_itemPath, subPath];
}

@end

@implementation UITableViewHeaderFooterView (HNItemPath)

- (NSString *)hinadata_itemPath {
    UITableView *tableView = (UITableView *)self.superview;

    while (![tableView isKindOfClass:UITableView.class]) {
        tableView = (UITableView *)tableView.superview;
        if (!tableView) {
            return super.hinadata_itemPath;
        }
    }
    for (NSInteger i = 0; i < tableView.numberOfSections; i++) {
        if (self == [tableView headerViewForSection:i]) {
            return [NSString stringWithFormat:@"[SectionHeader][%ld]", (long)i];
        }
        if (self == [tableView footerViewForSection:i]) {
            return [NSString stringWithFormat:@"[SectionFooter][%ld]", (long)i];
        }
    }
    return super.hinadata_itemPath;
}

@end

@implementation UITableViewCell (HNItemPath)

- (NSString *)hinadata_itemPath {
    NSIndexPath *indexPath = self.hinadata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.row];
    }
    return [super hinadata_itemPath];
}

@end

@implementation UICollectionViewCell (HNItemPath)

- (NSString *)hinadata_itemPath {
    NSIndexPath *indexPath = self.hinadata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][%ld]", NSStringFromClass(self.class), (long)indexPath.section, (long)indexPath.item];
    }
    return [super hinadata_itemPath];
}

@end

