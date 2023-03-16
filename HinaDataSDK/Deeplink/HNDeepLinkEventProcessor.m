//
// HNDeepLinkEventProcessor.m
// HinaDataSDK
//
// Created by hina on 2022/3/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDeepLinkEventProcessor.h"

@implementation HNDeepLinkEventProcessor

- (void)startWithProperties:(NSDictionary *)properties {
    [self trackDeepLinkLaunch:properties];
}

@end
