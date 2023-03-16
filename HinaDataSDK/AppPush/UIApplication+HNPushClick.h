//
// UIApplication+HNPushClick.h
// HinaDataSDK
//
// Created by hina on 2022/1/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (PushClick)

- (void)hinadata_setDelegate:(id <UIApplicationDelegate>)delegate;
@property (nonatomic, copy, nullable) NSDictionary *hinadata_launchOptions;

@end

NS_ASSUME_NONNULL_END
