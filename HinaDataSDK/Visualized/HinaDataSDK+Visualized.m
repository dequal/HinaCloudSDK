//
// HinaDataSDK+Visualized.m
// HinaDataSDK
//
// Created by hina on 2022/1/25.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HinaDataSDK+Visualized.h"
#import "HinaDataSDK+Private.h"
#import "HNVisualizedManager.h"

@implementation HinaDataSDK (Visualized)

#pragma mark - VisualizedAutoTrack
- (BOOL)isVisualizedAutoTrackEnabled {
    return self.configOptions.enableVisualizedAutoTrack || self.configOptions.enableVisualizedProperties;
}

- (void)addVisualizedAutoTrackViewControllers:(NSArray<NSString *> *)controllers {
    [[HNVisualizedManager defaultManager] addVisualizeWithViewControllers:controllers];
}

- (BOOL)isVisualizedAutoTrackViewController:(UIViewController *)viewController {
    return [[HNVisualizedManager defaultManager] isVisualizeWithViewController:viewController];
}

#pragma mark - HeatMap
- (BOOL)isHeatMapEnabled {
    return self.configOptions.enableHeatMap;
}

- (void)addHeatMapViewControllers:(NSArray<NSString *> *)controllers {
    [[HNVisualizedManager defaultManager] addVisualizeWithViewControllers:controllers];
}

- (BOOL)isHeatMapViewController:(UIViewController *)viewController {
    return [[HNVisualizedManager defaultManager] isVisualizeWithViewController:viewController];
}

@end
