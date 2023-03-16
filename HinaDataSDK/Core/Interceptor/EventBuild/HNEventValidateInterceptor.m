//
// HNEventValidateInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNEventValidateInterceptor.h"
#import "HNModuleManager.h"
#import "HNPropertyValidator.h"

@implementation HNEventValidateInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);

    // 事件名校验
    NSError *error = nil;
    [input.eventObject validateEventWithError:&error];
    if (error) {
        [HNModuleManager.sharedInstance showDebugModeWarning:error.localizedDescription];
    }
    input.message = error.localizedDescription;

    // 传入 properties 校验
    input.properties = [HNPropertyValidator validProperties:input.properties];
    completion(input);
}

@end
