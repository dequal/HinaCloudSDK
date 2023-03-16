//
// HNScrollViewDelegateProxy.m
// HinaDataSDK
//
// Created by hina on 2022/1/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNScrollViewDelegateProxy.h"
#import "HNAutoTrackUtils.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"
#import "UIScrollView+HNAutoTrack.h"
#import "HNAutoTrackManager.h"
#import <objc/message.h>
#import "UIScrollView+HNDelegateHashTable.h"

@implementation HNScrollViewDelegateProxy

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([tableView.hinadata_delegateHashTable containsObject:self]) {
        return;
    }
    [tableView.hinadata_delegateHashTable addObject:self];
    
    SEL methodSelector = @selector(tableView:didSelectRowAtIndexPath:);
    [HNScrollViewDelegateProxy trackEventWithTarget:self scrollView:tableView atIndexPath:indexPath];
    [HNScrollViewDelegateProxy invokeWithTarget:self selector:methodSelector, tableView, indexPath];
    
    [tableView.hinadata_delegateHashTable removeAllObjects];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // 防止某些场景下循环调用
    if ([collectionView.hinadata_delegateHashTable containsObject:self]) {
        return;
    }
    [collectionView.hinadata_delegateHashTable addObject:self];
    
    SEL methodSelector = @selector(collectionView:didSelectItemAtIndexPath:);
    [HNScrollViewDelegateProxy trackEventWithTarget:self scrollView:collectionView atIndexPath:indexPath];
    [HNScrollViewDelegateProxy invokeWithTarget:self selector:methodSelector, collectionView, indexPath];
    
    [collectionView.hinadata_delegateHashTable removeAllObjects];
}

+ (void)trackEventWithTarget:(NSObject *)target scrollView:(UIScrollView *)scrollView atIndexPath:(NSIndexPath *)indexPath {
    // 当 target 和 delegate 不相等时为消息转发, 此时无需重复采集事件
    if (target != scrollView.delegate) {
        return;
    }

    [HNAutoTrackManager.defaultManager.appClickTracker autoTrackEventWithScrollView:scrollView atIndexPath:indexPath];
}

@end
