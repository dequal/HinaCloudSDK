//
// UIScrollView+ExposureListener.h
// HinaDataSDK
//
// Created by hina on 2022/8/15.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableView (HNExposureListener)

- (void)hinadata_exposure_setDelegate:(id <UITableViewDelegate>)delegate;

@end

@interface UICollectionView (HNExposureListener)

- (void)hinadata_exposure_setDelegate:(id <UICollectionViewDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
