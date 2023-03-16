//
// UIView+HNAutoTrack.m
// HinaDataSDK
//
// Created by hina on 2022/6/11.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HNAutoTrack.h"
#import "HNAutoTrackUtils.h"
#import "HinaDataSDK+Private.h"
#import <objc/runtime.h>
#import "HNViewElementInfoFactory.h"
#import "HNAutoTrackManager.h"
#import "HNUIProperties.h"
#import "UIView+HNRNView.h"
#import "UIView+HinaData.h"

static void *const kHNLastAppClickIntervalPropertyName = (void *)&kHNLastAppClickIntervalPropertyName;

#pragma mark - UIView

@implementation UIView (AutoTrack)

- (BOOL)hinadata_isIgnored {
    if (self.isHidden || self.hinaDataIgnoreView) {
        return YES;
    }

    return [HNAutoTrackManager.defaultManager.appClickTracker isIgnoreEventWithView:self];
}

- (void)setHinadata_timeIntervalForLastAppClick:(NSTimeInterval)hinadata_timeIntervalForLastAppClick {
    objc_setAssociatedObject(self, kHNLastAppClickIntervalPropertyName, [NSNumber numberWithDouble:hinadata_timeIntervalForLastAppClick], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)hinadata_timeIntervalForLastAppClick {
    return [objc_getAssociatedObject(self, kHNLastAppClickIntervalPropertyName) doubleValue];
}

- (NSString *)hinadata_elementType {
    HNViewElementInfo *elementInfo = [HNViewElementInfoFactory elementInfoWithView:self];
    return elementInfo.elementType;
}

- (NSString *)hinadata_elementContent {
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

    NSMutableArray<NSString *> *elementContentArray = [NSMutableArray array];
    for (UIView *subview in self.subviews) {
        // 忽略隐藏控件
        if (subview.isHidden || subview.hinaDataIgnoreView) {
            continue;
        }
        NSString *temp = subview.hinadata_elementContent;
        if (temp.length > 0) {
            [elementContentArray addObject:temp];
        }
    }
    if (elementContentArray.count > 0) {
        return [elementContentArray componentsJoinedByString:@"-"];
    }
    
    return nil;
}

- (NSString *)hinadata_elementPosition {
    UIView *superView = self.superview;
    if (!superView) {
        return nil;
    }
    return superView.hinadata_elementPosition;
}

- (NSString *)hinadata_elementId {
    return self.hinaDataViewID;
}

@end

@implementation UILabel (AutoTrack)

- (NSString *)hinadata_elementContent {
    return self.text ?: super.hinadata_elementContent;
}

@end

@implementation UIImageView (AutoTrack)

- (NSString *)hinadata_elementContent {
    NSString *imageName = self.image.hinaDataImageName;
    if (imageName.length > 0) {
        return [NSString stringWithFormat:@"%@", imageName];
    }
    return super.hinadata_elementContent;
}

- (NSString *)hinadata_elementPosition {
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        NSInteger index = [HNUIProperties indexWithResponder:self];
        return index > 0 ? [NSString stringWithFormat:@"%ld", (long)index] : @"0";
    }
    return [super hinadata_elementPosition];
}

@end

@implementation UISearchBar (AutoTrack)

- (NSString *)hinadata_elementContent {
    return self.text;
}

@end

#pragma mark - UIControl

@implementation UIControl (AutoTrack)

- (BOOL)hinadata_isIgnored {
    // 忽略 UITabBarItem
    BOOL ignoredUITabBarItem = [[HinaDataSDK sdkInstance] isViewTypeIgnored:UITabBarItem.class] && [NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"];

    // 忽略 UIBarButtonItem
    BOOL ignoredUIBarButtonItem = [[HinaDataSDK sdkInstance] isViewTypeIgnored:UIBarButtonItem.class] && ([NSStringFromClass(self.class) isEqualToString:@"UINavigationButton"] || [NSStringFromClass(self.class) isEqualToString:@"_UIButtonBarButton"]);

    return super.hinadata_isIgnored || ignoredUITabBarItem || ignoredUIBarButtonItem;
}

- (NSString *)hinadata_elementType {
    // UIBarButtonItem
    if (([NSStringFromClass(self.class) isEqualToString:@"UINavigationButton"] || [NSStringFromClass(self.class) isEqualToString:@"_UIButtonBarButton"])) {
        return @"UIBarButtonItem";
    }

    // UITabBarItem
    if ([NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"]) {
        return @"UITabBarItem";
    }
    return NSStringFromClass(self.class);
}


- (NSString *)hinadata_elementPosition {
    // UITabBarItem
    if ([NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"]) {
        NSInteger index = [HNUIProperties indexWithResponder:self];
        if (index < 0) {
            index = 0;
        }
        return [NSString stringWithFormat:@"%ld", (long)index];
    }
    return super.hinadata_elementPosition;
}

@end

@implementation UIButton (AutoTrack)

- (NSString *)hinadata_elementContent {
    NSString *text = self.titleLabel.text;
    if (!text) {
        text = super.hinadata_elementContent;
    }
    return text;
}

@end

@implementation UISwitch (AutoTrack)

- (NSString *)hinadata_elementContent {
    return self.on ? @"checked" : @"unchecked";
}

@end

@implementation UIStepper (AutoTrack)

- (NSString *)hinadata_elementContent {
    return [NSString stringWithFormat:@"%g", self.value];
}

@end

@implementation UISegmentedControl (AutoTrack)

- (BOOL)hinadata_isIgnored {
    return super.hinadata_isIgnored || self.selectedSegmentIndex == UISegmentedControlNoSegment;
}

- (NSString *)hinadata_elementContent {
    return  self.selectedSegmentIndex == UISegmentedControlNoSegment ? [super hinadata_elementContent] : [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

- (NSString *)hinadata_elementPosition {
    return self.selectedSegmentIndex == UISegmentedControlNoSegment ? [super hinadata_elementPosition] : [NSString stringWithFormat: @"%ld", (long)self.selectedSegmentIndex];
}

@end

@implementation UIPageControl (AutoTrack)

- (NSString *)hinadata_elementContent {
    return [NSString stringWithFormat:@"%ld", (long)self.currentPage];
}

@end

@implementation UISlider (AutoTrack)

- (BOOL)hinadata_isIgnored {
    return self.tracking || super.hinadata_isIgnored;
}

- (NSString *)hinadata_elementContent {
    return [NSString stringWithFormat:@"%f", self.value];
}

@end

#pragma mark - Cell

@implementation UITableViewCell (AutoTrack)


- (NSString *)hinadata_elementPositionWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
}

@end

@implementation UICollectionViewCell (AutoTrack)

- (NSString *)hinadata_elementPositionWithIndexPath:(NSIndexPath *)indexPath {
    return [NSString stringWithFormat: @"%ld:%ld", (long)indexPath.section, (long)indexPath.item];
}

@end
