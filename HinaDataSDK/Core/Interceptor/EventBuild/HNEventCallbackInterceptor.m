//
// HNEventCallbackInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNEventCallbackInterceptor.h"
#import "HinaDataSDK.h"
#import "HNLog.h"

static NSString * const kHNEventCallbackKey = @"event_callback";

@interface HinaDataSDK ()

@property (nonatomic, copy) HNEventCallback trackEventCallback;

@end

#pragma mark -

@interface HNEventCallbackInterceptor ()

@property (nonatomic, copy) HNEventCallback callback;

@end

@implementation HNEventCallbackInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);

    NSString *eventName = input.eventObject.event;
    HNEventCallback callback = [HinaDataSDK sharedInstance].trackEventCallback;
    if (!callback || !eventName) {
        return completion(input);
    }

    BOOL willEnqueue = callback(eventName, input.eventObject.properties);
    if (!willEnqueue) {
        HNLogDebug(@"\n【track event】: %@ can not insert database.", eventName);

        input.state = HNFlowStateError;
        return completion(input);
    }

    // 校验 properties
    input.eventObject.properties = [HNPropertyValidator validProperties:input.eventObject.properties];

    completion(input);
}

@end
