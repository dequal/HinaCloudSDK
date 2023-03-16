//
// UIScrollView+ExposureListener.m
// HinaDataSDK
//
// Created by hina on 2022/8/15.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIScrollView+ExposureListener.h"
#import "HNExposureDelegateProxy.h"

@implementation UITableView (HNExposureListener)

- (void)hinadata_exposure_setDelegate:(id <UITableViewDelegate>)delegate {
    //resolve optional selectors
    [HNExposureDelegateProxy resolveOptionalSelectorsForDelegate:delegate];

    [self hinadata_exposure_setDelegate:delegate];

    if (!delegate || !self.delegate) {
        return;
    }

    // 使用委托类去 hook 点击事件方法
    [HNExposureDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"tableView:willDisplayCell:forRowAtIndexPath:", @"tableView:didEndDisplayingCell:forRowAtIndexPath:"]]];
}

@end


@implementation UICollectionView (HNExposureListener)

- (void)hinadata_exposure_setDelegate:(id <UICollectionViewDelegate>)delegate {
    //resolve optional selectors
    [HNExposureDelegateProxy resolveOptionalSelectorsForDelegate:delegate];

    [self hinadata_exposure_setDelegate:delegate];

    if (!delegate || !self.delegate) {
        return;
    }

    // 使用委托类去 hook 点击事件方法
    [HNExposureDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"collectionView:willDisplayCell:forItemAtIndexPath:", @"collectionView:didEndDisplayingCell:forItemAtIndexPath:"]]];
}

@end
