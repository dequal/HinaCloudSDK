//
// HNInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNInterceptor.h"

@implementation HNInterceptor

+ (instancetype)interceptorWithParam:(NSDictionary * _Nullable)param {
    return [[self alloc] init];
}

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSAssert(NO, @"The sub interceptor must implement this method.");
    completion(input);
}

@end
