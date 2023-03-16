//
// UIScrollView+HNDelegateHashTable.h
// HinaDataSDK
//
// Created by hina on 2022/9/3.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableView (HNDelegateHashTable)

@property (nonatomic, strong, nullable) NSHashTable *hinadata_delegateHashTable;

@property (nonatomic, strong, nullable) NSHashTable *hinadata_exposure_delegateHashTable;

@end

@interface UICollectionView (HNDelegateHashTable)

@property (nonatomic, strong, nullable) NSHashTable *hinadata_delegateHashTable;

@property (nonatomic, strong, nullable) NSHashTable *hinadata_exposure_delegateHashTable;

@end

NS_ASSUME_NONNULL_END
