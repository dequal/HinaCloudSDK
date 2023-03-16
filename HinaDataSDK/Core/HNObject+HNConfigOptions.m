//
// HNObject+HNConfigOptions.m
// HinaDataSDK
//
// Created by hina on 2022/6/30.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNObject+HNConfigOptions.h"
#import "HinaDataSDK+Private.h"
#import "HNLog.h"
#import "HNModuleManager.h"
#if __has_include("HNConfigOptions+Encrypt.h")
#import "HNConfigOptions+Encrypt.h"
#endif

@implementation HNDatabase (HNConfigOptions)

- (NSUInteger)maxCacheSize {
#ifdef DEBUG
    if (NSClassFromString(@"XCTestCase")) {
        return 10000;
    }
#endif
    return [HinaDataSDK sdkInstance].configOptions.maxCacheSize;
}

@end
