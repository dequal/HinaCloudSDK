//
// UIScrollView+HNAutoTrack.h
// HinaDataSDK
//
// Created by hina on 2022/6/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableView (AutoTrack)

- (void)hinadata_setDelegate:(id <UITableViewDelegate>)delegate;

@end

@interface UICollectionView (AutoTrack)

- (void)hinadata_setDelegate:(id <UICollectionViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
