//
// HinaDataSDK+DebugMode.m
// HinaDataSDK
//
// Created by hina on 2022/9/11.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HinaDataSDK+DebugMode.h"
#import "HNDebugModeManager.h"

@implementation HinaDataSDK (DebugMode)

- (void)showDebugInfoView:(BOOL)show {
    [[HNDebugModeManager defaultManager] setShowDebugAlertView:show];
}

@end
