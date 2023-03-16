//
// UIView+HNVisualPropertiey.h
// HinaDataSDK
//
// Created by hina on 2022/1/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import "HNViewNode.h"

@interface UIView (HNVisualProperties)

- (void)hinadata_visualize_didMoveToSuperview;

- (void)hinadata_visualize_didMoveToWindow;

- (void)hinadata_visualize_didAddSubview:(UIView *)subview;

- (void)hinadata_visualize_bringSubviewToFront:(UIView *)view;

- (void)hinadata_visualize_sendSubviewToBack:(UIView *)view;

/// 视图对应的节点
@property (nonatomic, strong) HNViewNode *hinadata_viewNode;

@end

@interface UITableViewCell(HNVisualProperties)

- (void)hinadata_visualize_prepareForReuse;

@end

@interface UICollectionViewCell(HNVisualProperties)

- (void)hinadata_visualize_prepareForReuse;

@end

@interface UITableViewHeaderFooterView(HNVisualProperties)

- (void)hinadata_visualize_prepareForReuse;

@end

@interface UIWindow (HNVisualProperties)

- (void)hinadata_visualize_becomeKeyWindow;

@end


@interface UITabBar (HNVisualProperties)
- (void)hinadata_visualize_setSelectedItem:(UITabBarItem *)selectedItem;
@end


#pragma mark - 属性内容
@interface UIView (PropertiesContent)

@property (nonatomic, copy, readonly) NSString *hinadata_propertyContent;

@end
