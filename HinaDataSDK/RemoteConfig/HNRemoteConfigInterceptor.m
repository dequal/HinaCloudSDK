//
// HNRemoteConfigInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNRemoteConfigInterceptor.h"
#import "HNModuleManager.h"

@implementation HNRemoteConfigInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);
    
    if ([HNModuleManager.sharedInstance isIgnoreEventObject:input.eventObject]) {
        input.state = HNFlowStateStop;
    }
    completion(input);
}

@end
