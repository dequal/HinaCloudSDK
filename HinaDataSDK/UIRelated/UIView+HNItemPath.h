//
// UIView+HNItemPath.h
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//


#import <UIKit/UIKit.h>
#import "HNUIViewPathProperties.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (HNItemPath) <HNUIViewPathProperties>

@end

@interface UISegmentedControl (HNItemPath) <HNUIViewPathProperties>

@end

@interface UITableViewHeaderFooterView (HNItemPath) <HNUIViewPathProperties>

@end

@interface UITableViewCell (HNItemPath) <HNUIViewPathProperties>

@end

@interface UICollectionViewCell (HNItemPath) <HNUIViewPathProperties>

@end

NS_ASSUME_NONNULL_END
