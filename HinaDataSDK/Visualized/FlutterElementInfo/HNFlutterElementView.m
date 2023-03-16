//
// HNFlutterElementView.m
// HinaDataSDK
//
// Created by  hina on 2022/5/27.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNFlutterElementView.h"

@implementation HNFlutterElementView


- (instancetype)initWithSuperView:(UIView *)superView elementInfo:(NSDictionary *)elementInfo {
    self = [super initWithSuperView:superView elementInfo:elementInfo];
    if (self) {
        self.platform = @"flutter";
    }
    return self;
}

@end
