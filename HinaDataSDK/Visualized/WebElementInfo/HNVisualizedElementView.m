//
// HNVisualizedElementView.m
// HinaDataSDK
//
// Created by  hina on 2022/5/27.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNVisualizedElementView.h"

@interface HNVisualizedElementView()

@end

@implementation HNVisualizedElementView

- (instancetype)initWithSuperView:(UIView *)superView elementInfo:(NSDictionary *)elementInfo {
    self = [super init];
    if (self) {
        CGFloat left = [elementInfo[@"left"] floatValue];
        CGFloat top = [elementInfo[@"top"] floatValue];
        CGFloat width = [elementInfo[@"width"] floatValue];
        CGFloat height = [elementInfo[@"height"] floatValue];
        if (height <= 0) {
            return nil;
        }

        CGRect viewRect = [superView convertRect:superView.bounds toView:nil];
        CGFloat realX = left + viewRect.origin.x;
        CGFloat realY = top + viewRect.origin.y;

        // H5 元素的显示位置
        CGRect touchViewRect = CGRectMake(realX, realY, width, height);
        // 计算 webView 和 H5 元素的交叉区域
        CGRect validFrame = CGRectIntersection(viewRect, touchViewRect);
        if (CGRectIsNull(validFrame) || CGSizeEqualToSize(validFrame.size, CGSizeZero)) {
            return nil;
        }
        [self setFrame:validFrame];

        self.userInteractionEnabled = YES;


        NSArray <NSString *> *subelements = elementInfo[@"subelements"];
        _subElementIds = subelements;
        _elementContent = elementInfo[@"H_element_content"];
        _title = elementInfo[@"title"];
        _screenName = elementInfo[@"screen_name"];
        _elementId = elementInfo[@"id"];
        _enableAppClick = [elementInfo[@"enable_click"] boolValue];
        _isListView = [elementInfo[@"is_list_view"] boolValue];
        _elementPath = elementInfo[@"H_element_path"];

        _elementPosition = elementInfo[@"H_element_position"];

        _level = [elementInfo[@"level"] integerValue];

        _platform = @"h5";

    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithString:NSStringFromClass(self.class)];
    if (self.elementContent) {
        [description appendFormat:@", elementContent:%@", self.elementContent];
    }
    if (self.level > 0) {
        [description appendFormat:@", level:%ld", (long)self.level];
    }
    if (self.elementPath) {
        [description appendFormat:@", elementPath:%@", self.elementPath];
    }
    [description appendFormat:@", enableAppClick:%@", @(self.enableAppClick)];

    if (self.elementPosition) {
        [description appendFormat:@", elementPosition:%@", self.elementPosition];
    }
    if (self.screenName) {
        [description appendFormat:@", screenName:%@", self.screenName];
    }
    if (self.subElements) {
        [description appendFormat:@", subElements:%@", self.subElements];
    }
    return [description copy];
}

@end
