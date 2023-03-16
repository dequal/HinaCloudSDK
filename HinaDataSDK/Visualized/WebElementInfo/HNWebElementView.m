//
// HNWebElementView.m
// HinaDataSDK
//
// Created by hina on 2022/2/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNWebElementView.h"

@interface HNWebElementView()

@end

@implementation HNWebElementView

- (instancetype)initWithWebView:(WKWebView *)webView webElementInfo:(NSDictionary *)elementInfo {
    self = [super initWithSuperView:webView elementInfo:elementInfo];
    if (self) {
        UIScrollView *scrollView = webView.scrollView;

        /// webView 缩放系数
        CGFloat zoomScale = scrollView.zoomScale;
        // 位置偏移量
        CGPoint contentOffset = scrollView.contentOffset;

        // NSInteger scale = [pageData[@"scale"] integerValue];
        CGFloat left = [elementInfo[@"left"] floatValue] * zoomScale;
        CGFloat top = [elementInfo[@"top"] floatValue] * zoomScale;
        CGFloat width = [elementInfo[@"width"] floatValue] * zoomScale;
        CGFloat height = [elementInfo[@"height"] floatValue] * zoomScale;

        CGFloat scrollX = [elementInfo[@"scrollX"] floatValue] * zoomScale;
        CGFloat scrollY = [elementInfo[@"scrollY"] floatValue] * zoomScale;
        BOOL visibility = [elementInfo[@"visibility"] boolValue];
        if (height <= 0 || !visibility) {
            return nil;
        }

        CGRect webViewRect = [webView convertRect:webView.bounds toView:nil];
        CGFloat realX = left + webViewRect.origin.x - contentOffset.x + scrollX;
        CGFloat realY = top + webViewRect.origin.y - contentOffset.y + scrollY;

        // H5 元素的显示位置
        CGRect touchViewRect = CGRectMake(realX, realY, width, height);
        // 计算 webView 和 H5 元素的交叉区域
        CGRect validFrame = CGRectIntersection(webViewRect, touchViewRect);
        if (CGRectIsNull(validFrame) || CGSizeEqualToSize(validFrame.size, CGSizeZero)) {
            return nil;
        }
        [self setFrame:validFrame];

        _elementSelector = elementInfo[@"H_element_selector"];
        _visible = visibility;
        _url = elementInfo[@"H_url"];
        _tagName = elementInfo[@"tagName"];

        _listSelector = elementInfo[@"list_selector"];
        _libVersion = elementInfo[@"lib_version"];

        // H5 元素 element_position 解析单独处理
        NSNumber *position = elementInfo[@"H_element_position"];
        if ([position isKindOfClass:NSNumber.class]) {
            self.elementPosition = [position stringValue];
        } else {
            self.elementPosition = nil;
        }
        self.platform = @"h5";
    }
    return self;
}

- (NSString *)description {
    NSMutableString *description = [NSMutableString stringWithString:[super description]];

    if (self.listSelector) {
        [description appendFormat:@", listSelector:%@", self.listSelector];
    }
    if (self.url) {
        [description appendFormat:@", url:%@", self.url];
    }
    return [description copy];
}
@end
