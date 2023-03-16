//
// HinaDataSDK+Location.m
// HinaDataSDK
//
// Created by hina on 2022/9/11.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HinaDataSDK+Location.h"
#import "HNLocationManager.h"

@implementation HinaDataSDK (Location)

- (void)enableTrackGPSLocation:(BOOL)enable {
    if (NSThread.isMainThread) {
        [HNLocationManager defaultManager].enable = enable;
        [HNLocationManager defaultManager].configOptions.enableLocation = enable;
    } else {
        dispatch_async(dispatch_get_main_queue(), ^ {
            [HNLocationManager defaultManager].enable = enable;
            [HNLocationManager defaultManager].configOptions.enableLocation = enable;
        });
    }
}

@end
