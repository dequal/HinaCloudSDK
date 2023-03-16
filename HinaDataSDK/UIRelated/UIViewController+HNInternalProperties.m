//
// UIViewController+HNInternalProperties.m
// HinaDataSDK
//
// Created by hina on 2022/8/30.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIViewController+HNInternalProperties.h"
#import "HNCommonUtility.h"
#import "UIView+HNElementContent.h"

@implementation UIViewController (HNInternalProperties)

- (NSString *)hinadata_screenName {
    return NSStringFromClass(self.class);
}

- (NSString *)hinadata_title {
    __block NSString *titleViewContent = nil;
    __block NSString *controllerTitle = nil;
    [HNCommonUtility performBlockOnMainThread:^{
        titleViewContent = self.navigationItem.titleView.hinadata_elementContent;
        controllerTitle = self.navigationItem.title;
    }];
    if (titleViewContent.length > 0) {
        return titleViewContent;
    }

    if (controllerTitle.length > 0) {
        return controllerTitle;
    }
    return nil;
}

@end
