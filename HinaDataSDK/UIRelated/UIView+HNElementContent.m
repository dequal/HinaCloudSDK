//
// UIView+HNElementContent.m
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HNElementContent.h"
#import "UIView+HinaData.h"

@implementation UIView (HNElementContent)

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
    if ([self isKindOfRNView:self]) { // RN 元素，https://reactnative.dev
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

- (BOOL)isKindOfRNView:(UIView *)view {
    NSString *className = NSStringFromClass(view.class);
    if ([className isEqualToString:@"UISegment"]) {
        // 针对 UISegment，可能是 RCTSegmentedControl 或 RNCSegmentedControl 内嵌元素，使用父视图判断是否为 RN 元素
        view = [view superview];
    }
    NSArray <NSString *> *classNames = @[@"RCTSurfaceView", @"RCTSurfaceHostingView", @"RCTFPSGraph", @"RCTModalHostView", @"RCTView", @"RCTTextView", @"RCTRootView",  @"RCTInputAccessoryView", @"RCTInputAccessoryViewContent", @"RNSScreenContainerView", @"RNSScreen", @"RCTVideo", @"RCTSwitch", @"RCTSlider", @"RCTSegmentedControl", @"RNGestureHandlerButton", @"RNCSlider", @"RNCSegmentedControl"];
    for (NSString *className in classNames) {
        Class class = NSClassFromString(className);
        if (class && [view isKindOfClass:class]) {
            return YES;
        }
    }
    return NO;
}

@end

@implementation UILabel (HNElementContent)

- (NSString *)hinadata_elementContent {
    return self.text ?: super.hinadata_elementContent;
}

@end

@implementation UIImageView (HNElementContent)

- (NSString *)hinadata_elementContent {
    NSString *imageName = self.image.hinaDataImageName;
    if (imageName.length > 0) {
        return [NSString stringWithFormat:@"%@", imageName];
    }
    return super.hinadata_elementContent;
}

@end

@implementation UISearchBar (HNElementContent)

- (NSString *)hinadata_elementContent {
    return self.text;
}

@end

@implementation UIButton (HNElementContent)

- (NSString *)hinadata_elementContent {
    NSString *text = self.titleLabel.text;
    if (!text) {
        text = super.hinadata_elementContent;
    }
    return text;

}

@end

@implementation UISwitch (HNElementContent)

- (NSString *)hinadata_elementContent {
    return self.on ? @"checked" : @"unchecked";
}

@end

@implementation UIStepper (HNElementContent)

- (NSString *)hinadata_elementContent {
    return [NSString stringWithFormat:@"%g", self.value];
}

@end

@implementation UISegmentedControl (HNElementContent)

- (NSString *)hinadata_elementContent {
    return  self.selectedSegmentIndex == UISegmentedControlNoSegment ? [super hinadata_elementContent] : [self titleForSegmentAtIndex:self.selectedSegmentIndex];
}

@end

@implementation UIPageControl (HNElementContent)

- (NSString *)hinadata_elementContent {
    return [NSString stringWithFormat:@"%ld", (long)self.currentPage];
}

@end

@implementation UISlider (HNElementContent)

- (NSString *)hinadata_elementContent {
    return [NSString stringWithFormat:@"%f", self.value];
}

@end
