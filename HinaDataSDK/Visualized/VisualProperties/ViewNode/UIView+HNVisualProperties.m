//
// UIView+HNVisualProperties.m
// HinaDataSDK
//
// Created by hina on 2022/1/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HNVisualProperties.h"
#import "HNVisualizedManager.h"
#import <objc/runtime.h>
#import "UIView+HNRNView.h"
#import "UIView+HinaData.h"

static void *const kHNViewNodePropertyName = (void *)&kHNViewNodePropertyName;

#pragma mark -
@implementation UIView (HNVisualProperties)

- (void)hinadata_visualize_didMoveToSuperview {
    [self hinadata_visualize_didMoveToSuperview];

    [HNVisualizedManager.defaultManager.visualPropertiesTracker didMoveToSuperviewWithView:self];
}

- (void)hinadata_visualize_didMoveToWindow {
    [self hinadata_visualize_didMoveToWindow];

    [HNVisualizedManager.defaultManager.visualPropertiesTracker didMoveToWindowWithView:self];
}

- (void)hinadata_visualize_didAddSubview:(UIView *)subview {
    [self hinadata_visualize_didAddSubview:subview];

    [HNVisualizedManager.defaultManager.visualPropertiesTracker didAddSubview:subview];
}

- (void)hinadata_visualize_bringSubviewToFront:(UIView *)view {
    [self hinadata_visualize_bringSubviewToFront:view];
    if (view.hinadata_viewNode) {
        // 移动节点
        [self.hinadata_viewNode.subNodes removeObject:view.hinadata_viewNode];
        [self.hinadata_viewNode.subNodes addObject:view.hinadata_viewNode];
        
        // 兄弟节点刷新 Index
        [view.hinadata_viewNode refreshBrotherNodeIndex];
    }
}

- (void)hinadata_visualize_sendSubviewToBack:(UIView *)view {
    [self hinadata_visualize_sendSubviewToBack:view];
    if (view.hinadata_viewNode) {
        // 移动节点
        [self.hinadata_viewNode.subNodes removeObject:view.hinadata_viewNode];
        [self.hinadata_viewNode.subNodes insertObject:view.hinadata_viewNode atIndex:0];
        
        // 兄弟节点刷新 Index
        [view.hinadata_viewNode refreshBrotherNodeIndex];
    }
}

- (void)setHinadata_viewNode:(HNViewNode *)hinadata_viewNode {
    objc_setAssociatedObject(self, kHNViewNodePropertyName, hinadata_viewNode, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (HNViewNode *)hinadata_viewNode {
    // 自定义属性被关闭，就不再操作 viewNode
    if (!HNVisualizedManager.defaultManager.visualPropertiesTracker) {
        return nil;
    }
    return objc_getAssociatedObject(self, kHNViewNodePropertyName);
}

/// 刷新节点位置信息
- (void)hinadata_refreshIndex {
    if (self.hinadata_viewNode) {
        [self.hinadata_viewNode refreshIndex];
    }
}

@end

@implementation UITableViewCell(HNVisualProperties)

- (void)hinadata_visualize_prepareForReuse {
    [self hinadata_visualize_prepareForReuse];

    // 重用后更新 indexPath
    [self hinadata_refreshIndex];
}

@end

@implementation UICollectionViewCell(HNVisualProperties)

- (void)hinadata_visualize_prepareForReuse {
    [self hinadata_visualize_prepareForReuse];

    // 重用后更新 indexPath
    [self hinadata_refreshIndex];
}

@end


@implementation UITableViewHeaderFooterView(HNVisualProperties)

- (void)hinadata_visualize_prepareForReuse {
    [self hinadata_visualize_prepareForReuse];

    // 重用后更新 index
    [self hinadata_refreshIndex];
}

@end

@implementation UIWindow(HNVisualProperties)
- (void)hinadata_visualize_becomeKeyWindow {
    [self hinadata_visualize_becomeKeyWindow];

    [HNVisualizedManager.defaultManager.visualPropertiesTracker becomeKeyWindow:self];
}

@end


@implementation UITabBar(HNVisualProperties)
- (void)hinadata_visualize_setSelectedItem:(UITabBarItem *)selectedItem {
    BOOL isSwitchTab = self.selectedItem == selectedItem;
    [self hinadata_visualize_setSelectedItem:selectedItem];

    // 当前已经是选中状态，即未切换 tab 修改页面，不需更新
    if (isSwitchTab) {
        return;
    }
    if (!HNVisualizedManager.defaultManager.visualPropertiesTracker) {
        return;
    }

    HNViewNode *tabBarNode = self.hinadata_viewNode;
    for (HNViewNode *node in tabBarNode.subNodes) {
        // 只需更新切换 item 对应 node 页面名称即可
        if ([node isKindOfClass:HNTabBarButtonNode.class] && [node.elementContent isEqualToString:selectedItem.title]) {
            // 共用自定义属性查询队列，从而保证更新页面信息后，再进行属性元素遍历
            dispatch_async(HNVisualizedManager.defaultManager.visualPropertiesTracker.serialQueue, ^{
                [node refreshSubNodeScreenName];
            });
        }
    }
}

@end

#pragma mark -
@implementation UIView (PropertiesContent)

- (NSString *)hinadata_propertyContent {
    if ([self isKindOfClass:NSClassFromString(@"RTLabel")]) {   // RTLabel:https://github.com/honcheng/RTLabel
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        if ([self respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [self performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                return title;
            }
        }
        return nil;
    }
    if ([self isKindOfClass:NSClassFromString(@"YYLabel")]) {    // RTLabel:https://github.com/ibireme/YYKit
        if ([self respondsToSelector:NSSelectorFromString(@"text")]) {
            NSString *title = [self performSelector:NSSelectorFromString(@"text")];
            if (title.length > 0) {
                return title;
            }
        }
        return nil;
#pragma clang diagnostic pop
    }
    if ([self isHinadataRNView]) { // RN 元素，https://reactnative.dev
        NSString *content = [self.accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (content.length > 0) {
            return content;
        }
    }

    if ([self isKindOfClass:NSClassFromString(@"WXView")]) { // WEEX 元素，http://doc.weex.io/zh/docs/components/a.html
        NSString *content = [self.accessibilityValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (content.length > 0) {
            return content;
        }
    }

    if ([[self nextResponder] isKindOfClass:UITextField.class] && ![self isKindOfClass:UIButton.class]) {
        /* 兼容输入框的元素采集
         UITextField 本身是一个容器，包括 UITextField 的元素内容，文字是直接渲染到 view 的
         层级结构如下
         UITextField
            _UITextFieldRoundedRectBackgroundViewNeue
            UIFieldEditor（UIScrollView 的子类，只有编辑状态才包含此层，非编辑状态直接包含下面层级）
                _UITextFieldCanvasView 或 _UISearchTextFieldCanvasView 或 _UITextLayoutCanvasView（模拟器出现） (UIView 的子类)
            _UITextFieldClearButton (可能存在)
         */
        UITextField *textField = (UITextField *)[self nextResponder];
        return [textField hinadata_propertyContent];
    }
    if ([NSStringFromClass(self.class) isEqualToString:@"_UITextFieldCanvasView"] || [NSStringFromClass(self.class) isEqualToString:@"_UISearchTextFieldCanvasView"] || [NSStringFromClass(self.class) isEqualToString:@"_UITextLayoutCanvasView"]) {
        
        UITextField *textField = (UITextField *)[self nextResponder];
        do {
            if ([textField isKindOfClass:UITextField.class]) {
                return [textField hinadata_propertyContent];
            }
        } while ((textField = (UITextField *)[textField nextResponder]));
        
        return nil;
    }

    NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
    for (UIView *subview in self.subviews) {
        // 忽略隐藏控件
        if (subview.isHidden || subview.hinaDataIgnoreView) {
            continue;
        }
        NSString *temp = subview.hinadata_propertyContent;
        if (temp.length > 0) {
            [elementContentArray addObject:temp];
        }
    }
    if (elementContentArray.count > 0) {
        return [elementContentArray componentsJoinedByString:@"-"];
    }
    
    return nil;
}

@end

@implementation UILabel (PropertiesContent)

- (NSString *)hinadata_propertyContent {
    return self.text ?: super.hinadata_propertyContent;
}

@end

@implementation UIImageView (PropertiesContent)

- (NSString *)hinadata_propertyContent {
    NSString *imageName = self.image.hinaDataImageName;
    if (imageName.length > 0) {
        return [NSString stringWithFormat:@"%@", imageName];
    }
    return super.hinadata_propertyContent;
}

@end


@implementation UITextField (PropertiesContent)

- (NSString *)hinadata_propertyContent {
	/*  兼容 RN 中输入框  placeholder 采集
	 RCTUITextField，未输入元素内容， text 为 @""，而非 nil
	 */
    if (self.text.length > 0) {
        return self.text;
    }
    return self.placeholder;
    /*
     针对 UITextField，因为子元素最终仍会尝试向上遍历 nextResponder 使用 UITextField本身获取内容
     如果再遍历子元素获取内容，会造成死循环调用而异常
     */
}

@end

@implementation UITextView (PropertiesContent)

- (NSString *)hinadata_propertyContent {
    return self.text ?: super.hinadata_propertyContent;
}

@end

@implementation UISearchBar (PropertiesContent)

- (NSString *)hinadata_propertyContent {
    return self.text ?: super.hinadata_propertyContent;
}

@end

#pragma mark - UIControl

@implementation UIButton (PropertiesContent)

- (NSString *)hinadata_propertyContent {
    NSString *text = self.titleLabel.text;
    if (!text) {
        text = super.hinadata_propertyContent;
    }
    return text;
}

@end

@implementation UISwitch (PropertiesContent)

- (NSString *)hinadata_propertyContent {
    return self.on ? @"checked" : @"unchecked";
}

@end

@implementation UIStepper (PropertiesContent)

- (NSString *)hinadata_propertyContent {
    return [NSString stringWithFormat:@"%g", self.value];
}

@end

@implementation UISegmentedControl (PropertiesContent)

- (NSString *)hinadata_propertyContent {
    return  self.selectedSegmentIndex == UISegmentedControlNoSegment ? [super hinadata_propertyContent] : [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

@end

@implementation UIPageControl (PropertiesContent)

- (NSString *)hinadata_propertyContent {
    return [NSString stringWithFormat:@"%ld", (long)self.currentPage];
}

@end

@implementation UISlider (PropertiesContent)

- (NSString *)hinadata_propertyContent {
    return [NSString stringWithFormat:@"%f", self.value];
}

@end
