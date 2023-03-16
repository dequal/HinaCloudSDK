//
// HNGeneralGestureViewProcessor.m
// HinaDataSDK
//
// Created by hina on 2022/2/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNGeneralGestureViewProcessor.h"
#import "UIGestureRecognizer+HNAutoTrack.h"
#import "HNAlertController.h"
#import "HNAutoTrackUtils.h"
#import "HNJSONUtil.h"
#import "HNUIProperties.h"

static NSArray <UIView *>* hinadata_searchVisualSubView(NSString *type, UIView *view) {
    NSMutableArray *subViews = [NSMutableArray array];
    for (UIView *subView in view.subviews) {
        if ([type isEqualToString:NSStringFromClass(subView.class)]) {
            [subViews addObject:subView];
        } else {
            NSArray *array = hinadata_searchVisualSubView(type, subView);
            if (array.count > 0) {
                [subViews addObjectsFromArray:array];
            }
        }
    }
    return  [subViews copy];
}

@interface HNGeneralGestureViewProcessor ()

@property (nonatomic, strong) UIGestureRecognizer *gesture;

@end

@implementation HNGeneralGestureViewProcessor

- (instancetype)initWithGesture:(UIGestureRecognizer *)gesture {
    if (self = [super init]) {
        self.gesture = gesture;
    }
    return self;
}

- (BOOL)isTrackable {
    if ([self isIgnoreWithView:self.gesture.view]) {
        return NO;
    }
    if ([HNGestureTargetActionModel filterValidModelsFrom:self.gesture.hinadata_targetActionModels].count == 0) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableView {
    return self.gesture.view;
}

#pragma mark - private method
- (BOOL)isIgnoreWithView:(UIView *)view {
    static dispatch_once_t onceToken;
    static id info = nil;
    dispatch_once(&onceToken, ^{
        NSBundle *hinaBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"HinaDataSDK" ofType:@"bundle"]];
        NSString *jsonPath = [hinaBundle pathForResource:@"sa_autotrack_gestureview_blacklist.json" ofType:nil];
        NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
        if (jsonData) {
            info = [HNJSONUtil JSONObjectWithData:jsonData];
        }
    });
    if (![info isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    // 公开类名使用 - isKindOfClass: 判断
    id publicClasses = info[@"public"];
    if ([publicClasses isKindOfClass:NSArray.class]) {
        for (NSString *publicClass in (NSArray *)publicClasses) {
            if ([view isKindOfClass:NSClassFromString(publicClass)]) {
                return YES;
            }
        }
    }
    // 私有类名使用字符串匹配判断
    id privateClasses = info[@"private"];
    if ([privateClasses isKindOfClass:NSArray.class]) {
        if ([(NSArray *)privateClasses containsObject:NSStringFromClass(view.class)]) {
            return YES;
        }
    }
    return NO;
}

@end

#pragma mark - 适配 iOS 10 以前的 Alert
@implementation HNLegacyAlertGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    // 屏蔽 HNAlertController 的点击事件
    UIViewController *viewController = [HNUIProperties findNextViewControllerByResponder:self.gesture.view];
    if ([viewController isKindOfClass:UIAlertController.class] && [viewController.nextResponder isKindOfClass:HNAlertController.class]) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableView {
    NSArray <UIView *>*visualViews = hinadata_searchVisualSubView(@"_UIAlertControllerCollectionViewCell", self.gesture.view);
    CGPoint currentPoint = [self.gesture locationInView:self.gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:self.gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - 适配 iOS 10 及以后的 Alert
@implementation HNNewAlertGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    // 屏蔽 HNAlertController 的点击事件
    UIViewController *viewController = [HNUIProperties findNextViewControllerByResponder:self.gesture.view];
    if ([viewController isKindOfClass:UIAlertController.class] && [viewController.nextResponder isKindOfClass:HNAlertController.class]) {
        return NO;
    }
    return YES;
}

- (UIView *)trackableView {
    NSArray <UIView *>*visualViews = hinadata_searchVisualSubView(@"_UIInterfaceActionCustomViewRepresentationView", self.gesture.view);
    CGPoint currentPoint = [self.gesture locationInView:self.gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:self.gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - 适配 iOS 13 的 UIMenu
@implementation HNLegacyMenuGestureViewProcessor

- (UIView *)trackableView {
    NSArray <UIView *>*visualViews = hinadata_searchVisualSubView(@"_UIContextMenuActionView", self.gesture.view);
    CGPoint currentPoint = [self.gesture locationInView:self.gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:self.gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - 适配 iOS 14 及以后的 UIMenu
@implementation HNMenuGestureViewProcessor

- (UIView *)trackableView {
    NSArray <UIView *>*visualViews = hinadata_searchVisualSubView(@"_UIContextMenuActionsListCell", self.gesture.view);
    CGPoint currentPoint = [self.gesture locationInView:self.gesture.view];
    for (UIView *visualView in visualViews) {
        CGRect rect = [visualView convertRect:visualView.bounds toView:self.gesture.view];
        if (CGRectContainsPoint(rect, currentPoint)) {
            return visualView;
        }
    }
    return nil;
}

@end

#pragma mark - TableViewCell.contentView 上仅存在系统手势时, 不支持可视化全埋点元素选中
@implementation HNTableCellGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    for (HNGestureTargetActionModel *model in self.gesture.hinadata_targetActionModels) {
        if (model.isValid && ![NSStringFromSelector(model.action) isEqualToString:@"_longPressGestureRecognized:"]) {
            return YES;
        }
    }
    return NO;
}

@end

#pragma mark - CollectionViewCell.contentView 上仅存在系统手势时, 不支持可视化全埋点元素选中
@implementation HNCollectionCellGestureViewProcessor

- (BOOL)isTrackable {
    if (![super isTrackable]) {
        return NO;
    }
    for (HNGestureTargetActionModel *model in self.gesture.hinadata_targetActionModels) {
        if (model.isValid && ![NSStringFromSelector(model.action) isEqualToString:@"_handleMenuGesture:"]) {
            return YES;
        }
    }
    return NO;
}

@end
