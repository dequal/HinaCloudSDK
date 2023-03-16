//
// UIScrollView+HNAutoTrack.m
// HinaDataSDK
//
// Created by hina on 2022/6/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIScrollView+HNAutoTrack.h"
#import "HNScrollViewDelegateProxy.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "HNConstants+Private.h"
#import "HNAutoTrackManager.h"

@implementation UITableView (AutoTrack)

- (void)hinadata_setDelegate:(id <UITableViewDelegate>)delegate {
    //resolve optional selectors
    [HNScrollViewDelegateProxy resolveOptionalSelectorsForDelegate:delegate];
    
    [self hinadata_setDelegate:delegate];

    if (!delegate || !self.delegate) {
        return;
    }
    
    // 判断是否忽略 H_AppClick 事件采集
    if ([HNAutoTrackManager.defaultManager isAutoTrackEventTypeIgnored:HinaDataEventTypeAppClick]) {
        return;
    }
    
    // 使用委托类去 hook 点击事件方法
    [HNScrollViewDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"tableView:didSelectRowAtIndexPath:"]]];
}

@end


@implementation UICollectionView (AutoTrack)

- (void)hinadata_setDelegate:(id <UICollectionViewDelegate>)delegate {
    //resolve optional selectors
    [HNScrollViewDelegateProxy resolveOptionalSelectorsForDelegate:delegate];
    
    [self hinadata_setDelegate:delegate];
    
    if (!delegate || !self.delegate) {
        return;
    }
    
    // 判断是否忽略 H_AppClick 事件采集
    if ([HNAutoTrackManager.defaultManager isAutoTrackEventTypeIgnored:HinaDataEventTypeAppClick]) {
        return;
    }
    
    // 使用委托类去 hook 点击事件方法
    [HNScrollViewDelegateProxy proxyDelegate:self.delegate selectors:[NSSet setWithArray:@[@"collectionView:didSelectItemAtIndexPath:"]]];
}

@end
