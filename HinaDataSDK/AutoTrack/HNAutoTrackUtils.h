//
// HNAutoTrackUtils.h
// HinaDataSDK
//
// Created by hina on 2022/4/22.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.

    

#import <UIKit/UIKit.h>
#import "HNAutoTrackProperty.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNAutoTrackUtils : NSObject

/// 在间隔时间内是否采集 H_AppClick 全埋点
+ (BOOL)isValidAppClickForObject:(id<HNAutoTrackViewProperty>)object;

@end

#pragma mark -
@interface HNAutoTrackUtils (Property)

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @return 事件属性字典
 */
+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<HNAutoTrackViewProperty>)object;

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @param isCodeTrack 是否代码埋点采集
 @return 事件属性字典
 */
+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<HNAutoTrackViewProperty>)object isCodeTrack:(BOOL)isCodeTrack;

/**
 通过 AutoTrack 控件，获取事件的属性

 @param object 控件的对象，UIView 及其子类或 UIBarItem 的子类
 @param viewController 控件所在的 ViewController，当为 nil 时，自动采集当前界面上的 ViewController
 @return 事件属性字典
 */
+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(id<HNAutoTrackViewProperty>)object viewController:(nullable UIViewController<HNAutoTrackViewControllerProperty> *)viewController;

@end

#pragma mark -
@interface HNAutoTrackUtils (IndexPath)

+ (nullable NSMutableDictionary<NSString *, NSString *> *)propertiesWithAutoTrackObject:(UIScrollView<HNAutoTrackViewProperty> *)object didSelectedAtIndexPath:(NSIndexPath *)indexPath;

+ (UIView *)cellWithScrollView:(UIScrollView *)scrollView selectedAtIndexPath:(NSIndexPath *)indexPath;

+ (NSDictionary *)propertiesWithAutoTrackDelegate:(UIScrollView *)scrollView didSelectedAtIndexPath:(NSIndexPath *)indexPath;
@end

NS_ASSUME_NONNULL_END
