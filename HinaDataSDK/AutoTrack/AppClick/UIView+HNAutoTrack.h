//
// UIView+HNAutoTrack.h
// HinaDataSDK
//
// Created by hina on 2022/6/11.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <UIKit/UIKit.h>
#import "HNAutoTrackProperty.h"

#pragma mark - UIView

@interface UIView (AutoTrack) <HNAutoTrackViewProperty>
@end

@interface UILabel (AutoTrack) <HNAutoTrackViewProperty>
@end

@interface UIImageView (AutoTrack) <HNAutoTrackViewProperty>
@end

@interface UISearchBar (AutoTrack) <HNAutoTrackViewProperty>
@end

#pragma mark - UIControl

@interface UIControl (AutoTrack) <HNAutoTrackViewProperty>
@end

@interface UIButton (AutoTrack) <HNAutoTrackViewProperty>
@end

@interface UISwitch (AutoTrack) <HNAutoTrackViewProperty>
@end

@interface UIStepper (AutoTrack) <HNAutoTrackViewProperty>
@end

@interface UISegmentedControl (AutoTrack) <HNAutoTrackViewProperty>
@end


@interface UIPageControl (AutoTrack) <HNAutoTrackViewProperty>
@end

#pragma mark - Cell
@interface UITableViewCell (AutoTrack) <HNAutoTrackCellProperty>
@end

@interface UICollectionViewCell (AutoTrack) <HNAutoTrackCellProperty>
@end
