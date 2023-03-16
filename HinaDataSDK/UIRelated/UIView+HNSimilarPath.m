//
// UIView+HNSimilarPath.m
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HNSimilarPath.h"
#import "UIView+HNElementPosition.h"
#import "UIView+HNItemPath.h"
#import "UITableViewCell+HNIndexPath.h"

@implementation UIView (HNSimilarPath)

- (NSString *)hinadata_similarPath {
    // 是否支持限定元素位置功能
    BOOL enableSupportSimilarPath = [NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"];
    if (enableSupportSimilarPath && self.hinadata_elementPosition) {
        return [NSString stringWithFormat:@"%@[-]",NSStringFromClass(self.class)];
    } else {
        return self.hinadata_itemPath;
    }
}

@end

@implementation UISegmentedControl (HNSimilarPath)

- (NSString *)hinadata_similarPath {
    return [NSString stringWithFormat:@"%@/UISegment[-]", super.hinadata_itemPath];
}

@end

@implementation UITableViewCell (HNSimilarPath)

- (NSString *)hinadata_similarPath {
    NSIndexPath *indexPath = self.hinadata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][-]", NSStringFromClass(self.class), (long)indexPath.section];
    }
    return self.hinadata_itemPath;
}

@end

@implementation UICollectionViewCell (HNSimilarPath)

- (NSString *)hinadata_similarPath {
    NSIndexPath *indexPath = self.hinadata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%@[%ld][-]", NSStringFromClass(self.class), (long)indexPath.section];
    } else {
        return super.hinadata_similarPath;
    }
}

@end
