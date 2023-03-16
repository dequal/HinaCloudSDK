//
// HNAutoTrackProperty.h
// HinaDataSDK
//
// Created by hina on 2022/4/23.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.

    

#import <Foundation/Foundation.h>

@protocol HNAutoTrackViewControllerProperty <NSObject>

@property (nonatomic, readonly) BOOL hinadata_isIgnored;

@end

#pragma mark -
@protocol HNAutoTrackViewProperty <NSObject>

@property (nonatomic, readonly) BOOL hinadata_isIgnored;
/// 记录上次触发点击事件的开机时间
@property (nonatomic, assign) NSTimeInterval hinadata_timeIntervalForLastAppClick;

@end

#pragma mark -
@protocol HNAutoTrackCellProperty <HNAutoTrackViewProperty>

- (NSString *)hinadata_elementPositionWithIndexPath:(NSIndexPath *)indexPath;

@end
