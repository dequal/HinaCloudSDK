//
// HNNewCellClickPlugin.m
// HinaDataSDK
//
// Created by hina on 2022/11/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNCellClickDynamicSubclassPlugin.h"
#import "HNSwizzle.h"
#import <UIKit/UIKit.h>

static NSString *const kHNEventTrackerPluginType = @"AppClick+ScrollView";

@implementation HNCellClickDynamicSubclassPlugin

- (void)install {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod];
    });
    self.enable = YES;
}

- (void)uninstall {
    self.enable = NO;
}

- (NSString *)type {
    return kHNEventTrackerPluginType;
}

- (void)swizzleMethod {
    SEL selector = NSSelectorFromString(@"hinadata_setDelegate:");
    [UITableView sa_swizzleMethod:@selector(setDelegate:)
                       withMethod:selector
                            error:NULL];
    [UICollectionView sa_swizzleMethod:@selector(setDelegate:)
                            withMethod:selector
                                 error:NULL];
}

@end
