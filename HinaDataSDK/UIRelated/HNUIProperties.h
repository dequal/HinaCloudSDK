//
// HNUIProperties.h
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNUIProperties : NSObject

+ (NSInteger)indexWithResponder:(UIResponder *)responder;

+ (BOOL)isIgnoredItemPathWithView:(UIView *)view;

+ (NSString *)elementPathForView:(UIView *)view atViewController:(UIViewController *)viewController;

+ (nullable UIViewController *)findNextViewControllerByResponder:(UIResponder *)responder;

+ (UIViewController *)currentViewController;

+ (NSDictionary *)propertiesWithView:(UIView *)view viewController:(UIViewController *)viewController;

+ (NSDictionary *)propertiesWithScrollView:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath;

+ (NSDictionary *)propertiesWithScrollView:(UIScrollView *)scrollView cell:(UIView *)cell;

+ (NSDictionary *)propertiesWithViewController:(UIViewController *)viewController;

+ (NSDictionary *)propertiesWithAutoTrackDelegate:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath;

+ (UIView *)cellWithScrollView:(UIScrollView *)scrollView andIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
