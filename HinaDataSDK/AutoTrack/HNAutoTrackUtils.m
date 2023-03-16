//
// HNAutoTrackUtils.m
// HinaDataSDK
//
// Created by hina on 2022/4/22.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAutoTrackUtils.h"
#import "HNConstants+Private.h"
#import "HNCommonUtility.h"
#import "HinaDataSDK.h"
#import "UIView+HNAutoTrack.h"
#import "HNLog.h"
#import "HNAlertController.h"
#import "HNModuleManager.h"
#import "HNValidator.h"
#import "UIView+HNInternalProperties.h"
#import "HNUIProperties.h"
#import "UIView+HinaData.h"

/// 一个元素 H_AppClick 全埋点最小时间间隔，100 毫秒
static NSTimeInterval HNTrackAppClickMinTimeInterval = 0.1;

@implementation HNAutoTrackUtils

/// 在间隔时间内是否采集 H_AppClick 全埋点
+ (BOOL)isValidAppClickForObject:(id<HNAutoTrackViewProperty>)object {
    if (!object) {
        return NO;
    }
    
    if (![object respondsToSelector:@selector(hinadata_timeIntervalForLastAppClick)]) {
        return YES;
    }

    NSTimeInterval lastTime = object.hinadata_timeIntervalForLastAppClick;
    NSTimeInterval currentTime = [[NSProcessInfo processInfo] systemUptime];
    if (lastTime > 0 && currentTime - lastTime < HNTrackAppClickMinTimeInterval) {
        return NO;
    }
    return YES;
}

@end

#pragma mark -
@implementation HNAutoTrackUtils (Property)

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIView<HNAutoTrackViewProperty> *)object {
    return [self propertiesWithAutoTrackObject:object viewController:nil isCodeTrack:NO];
}

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIView<HNAutoTrackViewProperty> *)object isCodeTrack:(BOOL)isCodeTrack {
    return [self propertiesWithAutoTrackObject:object viewController:nil isCodeTrack:isCodeTrack];
}

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIView<HNAutoTrackViewProperty> *)object viewController:(nullable UIViewController<HNAutoTrackViewControllerProperty> *)viewController {
    return [self propertiesWithAutoTrackObject:object viewController:viewController isCodeTrack:NO];
}

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIView<HNAutoTrackViewProperty> *)object viewController:(nullable UIViewController<HNAutoTrackViewControllerProperty> *)viewController isCodeTrack:(BOOL)isCodeTrack {
    if (![object respondsToSelector:@selector(hinadata_isIgnored)] || (!isCodeTrack && object.hinadata_isIgnored)) {
        return nil;
    }

    viewController = viewController ? : object.hinadata_viewController;
    if (!isCodeTrack && viewController.hinadata_isIgnored) {
        return nil;
    }
    NSDictionary *properties = [HNUIProperties propertiesWithView:object viewController:viewController];
    return [NSMutableDictionary dictionaryWithDictionary:properties];
}

@end

#pragma mark -
@implementation HNAutoTrackUtils (IndexPath)

+ (NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIScrollView<HNAutoTrackViewProperty> *)object didSelectedAtIndexPath:(NSIndexPath *)indexPath {
    if (![object respondsToSelector:@selector(hinadata_isIgnored)] || object.hinadata_isIgnored) {
        return nil;
    }
    NSDictionary *properties = [HNUIProperties propertiesWithScrollView:object andIndexPath:indexPath];
    return [NSMutableDictionary dictionaryWithDictionary:properties];
}

+ (UIView *)cellWithScrollView:(UIScrollView *)scrollView selectedAtIndexPath:(NSIndexPath *)indexPath {
    UIView *cell = nil;
    if ([scrollView isKindOfClass:UITableView.class]) {
        UITableView *tableView = (UITableView *)scrollView;
        cell = [tableView cellForRowAtIndexPath:indexPath];
        if (!cell) {
            [tableView layoutIfNeeded];
            cell = [tableView cellForRowAtIndexPath:indexPath];
        }
    } else if ([scrollView isKindOfClass:UICollectionView.class]) {
        UICollectionView *collectionView = (UICollectionView *)scrollView;
        cell = [collectionView cellForItemAtIndexPath:indexPath];
        if (!cell) {
            [collectionView layoutIfNeeded];
            cell = [collectionView cellForItemAtIndexPath:indexPath];
        }
    }
    return cell;
}

+ (NSDictionary *)propertiesWithAutoTrackDelegate:(UIScrollView *)scrollView didSelectedAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *properties = nil;
    @try {
        if ([scrollView isKindOfClass:UITableView.class]) {
            UITableView *tableView = (UITableView *)scrollView;
            
            if ([tableView.hinaDataDelegate respondsToSelector:@selector(hinaData_tableView:autoTrackPropertiesAtIndexPath:)]) {
                properties = [tableView.hinaDataDelegate hinaData_tableView:tableView autoTrackPropertiesAtIndexPath:indexPath];
            }
        } else if ([scrollView isKindOfClass:UICollectionView.class]) {
            UICollectionView *collectionView = (UICollectionView *)scrollView;
            if ([collectionView.hinaDataDelegate respondsToSelector:@selector(hinaData_collectionView:autoTrackPropertiesAtIndexPath:)]) {
                properties = [collectionView.hinaDataDelegate hinaData_collectionView:collectionView autoTrackPropertiesAtIndexPath:indexPath];
            }
        }
    } @catch (NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
    NSAssert(!properties || [properties isKindOfClass:[NSDictionary class]], @"You must return a dictionary object ❌");
    return properties;
}
@end
