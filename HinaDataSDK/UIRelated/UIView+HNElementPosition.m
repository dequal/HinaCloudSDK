//
// UIView+HNElementPosition.m
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HNElementPosition.h"
#import "HNUIProperties.h"
#import "UITableViewCell+HNIndexPath.h"

@implementation UIView (HNElementPosition)

- (NSString *)hinadata_elementPosition {
    UIView *superView = self.superview;
    if (!superView) {
        return nil;
    }
    return superView.hinadata_elementPosition;
}

@end

@implementation UIImageView (HNElementPosition)

- (NSString *)hinadata_elementPosition {
    if ([NSStringFromClass(self.class) isEqualToString:@"UISegment"]) {
        NSInteger index = [HNUIProperties indexWithResponder:self];
        return index > 0 ? [NSString stringWithFormat:@"%ld", (long)index] : @"0";
    }
    return [super hinadata_elementPosition];
}

@end

@implementation UIControl (HNElementPosition)

- (NSString *)hinadata_elementPosition {
    if ([NSStringFromClass(self.class) isEqualToString:@"UITabBarButton"]) {
        NSInteger index = [HNUIProperties indexWithResponder:self];
        if (index < 0) {
            index = 0;
        }
        return [NSString stringWithFormat:@"%ld", (long)index];
    }
    return super.hinadata_elementPosition;
}

@end

@implementation UISegmentedControl (HNElementPosition)

- (NSString *)hinadata_elementPosition {
    return self.selectedSegmentIndex == UISegmentedControlNoSegment ? [super hinadata_elementPosition] : [NSString stringWithFormat: @"%ld", (long)self.selectedSegmentIndex];
}

@end

@implementation UITableViewCell (HNElementPosition)

- (NSString *)hinadata_elementPosition {
    NSIndexPath *indexPath = self.hinadata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%ld:%ld", (long)indexPath.section, (long)indexPath.row];
    }
    return nil;
}

@end

@implementation UICollectionViewCell (HNElementPosition)

- (NSString *)hinadata_elementPosition {
    NSIndexPath *indexPath = self.hinadata_IndexPath;
    if (indexPath) {
        return [NSString stringWithFormat:@"%ld:%ld", (long)indexPath.section, (long)indexPath.item];
    }
    return nil;
}

@end
