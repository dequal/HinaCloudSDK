//
// UIViewController+PageView.h
// HinaDataSDK
//
// Created by hina on 2022/7/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (HNPageLeave)

- (void)hinadata_pageLeave_viewDidAppear:(BOOL)animated;

- (void)hinadata_pageLeave_viewDidDisappear:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
