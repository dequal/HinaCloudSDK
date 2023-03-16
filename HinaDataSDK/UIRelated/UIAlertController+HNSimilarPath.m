//
// UIAlertController+HNSimilarPath.m
// HinaDataSDK
//
// Created by hina on 2022/8/30.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIAlertController+HNSimilarPath.h"
#import "HNUIProperties.h"

@implementation UIAlertController (HNSimilarPath)

- (NSString *)hinadata_similarPath {
    NSString *className = NSStringFromClass(self.class);
    NSInteger index = [HNUIProperties indexWithResponder:self];
    if (index < 0) { // -1
        return className;
    }
    return [NSString stringWithFormat:@"%@[%ld]", className, (long)index];
}

@end
