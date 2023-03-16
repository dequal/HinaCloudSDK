//
// UIViewController+HNAutoTrack.h
// HinaDataSDK
//
// Created by hina on 2022/10/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import "HNAutoTrackProperty.h"

@interface UIViewController (AutoTrack) <HNAutoTrackViewControllerProperty>

- (void)sa_autotrack_viewDidAppear:(BOOL)animated;

@end

@interface UINavigationController (AutoTrack)

/// 上一次页面，防止侧滑/下滑重复采集 H_AppViewScreen 事件
@property (nonatomic, strong) UIViewController *hinadata_previousViewController;

@end
