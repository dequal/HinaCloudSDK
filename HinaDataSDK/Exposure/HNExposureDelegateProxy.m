//
// HNExposureDelegateProxy.m
// HinaDataSDK
//
// Created by hina on 2022/8/15.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNExposureDelegateProxy.h"
#import <UIKit/UIKit.h>
#import "HNExposureViewObject.h"
#import "HNExposureManager.h"
#import "UIScrollView+HNDelegateHashTable.h"
#import <objc/runtime.h>
#import "HNLog.h"

@implementation HNExposureDelegateProxy

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([tableView.hinadata_exposure_delegateHashTable containsObject:self]) {
        return;
    }
    [tableView.hinadata_exposure_delegateHashTable addObject:self];

    HNExposureViewObject *exposureViewObject = [[HNExposureManager defaultManager] exposureViewWithView:cell];
    exposureViewObject.state = (exposureViewObject.state == HNExposureViewStateExposing ? HNExposureViewStateExposing : HNExposureViewStateVisible);
    exposureViewObject.scrollView = tableView;
    exposureViewObject.indexPath = indexPath;

    //invoke original
    SEL methodSelector = @selector(tableView:willDisplayCell:forRowAtIndexPath:);
    if (class_getInstanceMethod(tableView.delegate.class, methodSelector)) {
        [HNExposureDelegateProxy invokeWithTarget:self selector:methodSelector, tableView, cell, indexPath];
    }

    [tableView.hinadata_exposure_delegateHashTable removeAllObjects];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([tableView.hinadata_exposure_delegateHashTable containsObject:self]) {
        return;
    }
    [tableView.hinadata_exposure_delegateHashTable addObject:self];

    HNExposureViewObject *exposureViewObject = [[HNExposureManager defaultManager] exposureViewWithView:cell];
    if (![tableView.indexPathsForVisibleRows containsObject:indexPath]) {
        exposureViewObject.state = HNExposureViewStateInvisible;
    }

    //invoke original
    SEL methodSelector = @selector(tableView:didEndDisplayingCell:forRowAtIndexPath:);
    if (class_getInstanceMethod(tableView.delegate.class, methodSelector)) {
        [HNExposureDelegateProxy invokeWithTarget:self selector:methodSelector, tableView, cell, indexPath];
    }

    [tableView.hinadata_exposure_delegateHashTable removeAllObjects];
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([collectionView.hinadata_exposure_delegateHashTable containsObject:self]) {
        return;
    }
    [collectionView.hinadata_exposure_delegateHashTable addObject:self];
    
    HNExposureViewObject *exposureViewObject = [[HNExposureManager defaultManager] exposureViewWithView:cell];
    exposureViewObject.state = (exposureViewObject.state == HNExposureViewStateExposing ? HNExposureViewStateExposing : HNExposureViewStateVisible);
    exposureViewObject.scrollView = collectionView;
    exposureViewObject.indexPath = indexPath;

    //invoke original
    SEL methodSelector = @selector(collectionView:willDisplayCell:forItemAtIndexPath:);
    if (class_getInstanceMethod(collectionView.delegate.class, methodSelector)) {
        [HNExposureDelegateProxy invokeWithTarget:self selector:methodSelector, collectionView, cell, indexPath];
    }

    [collectionView.hinadata_exposure_delegateHashTable removeAllObjects];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([collectionView.hinadata_exposure_delegateHashTable containsObject:self]) {
        return;
    }
    [collectionView.hinadata_exposure_delegateHashTable addObject:self];

    HNExposureViewObject *exposureViewObject = [[HNExposureManager defaultManager] exposureViewWithView:cell];
    if (![collectionView.indexPathsForVisibleItems containsObject:indexPath]) {
        exposureViewObject.state = HNExposureViewStateInvisible;
    }

    //invoke original
    SEL methodSelector = @selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:);
    if (class_getInstanceMethod(collectionView.delegate.class, methodSelector)) {
        [HNExposureDelegateProxy invokeWithTarget:self selector:methodSelector, collectionView, cell, indexPath];
    }

    [collectionView.hinadata_exposure_delegateHashTable removeAllObjects];
}

+ (NSSet<NSString *> *)optionalSelectors {
    return [NSSet setWithArray:@[@"tableView:willDisplayCell:forRowAtIndexPath:", @"tableView:didEndDisplayingCell:forRowAtIndexPath:", @"collectionView:willDisplayCell:forItemAtIndexPath:", @"collectionView:didEndDisplayingCell:forItemAtIndexPath:"]];
}

@end
