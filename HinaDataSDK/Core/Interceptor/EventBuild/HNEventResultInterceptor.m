//
// HNEventResultInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/13.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNEventResultInterceptor.h"
#import "HNEventRecord.h"
#import "HNConstants+Private.h"
#import "HNLog.h"

@implementation HNEventResultInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);
    
    NSMutableDictionary *event = input.eventObject.jsonObject;

    // H5 打通事件
    if (input.eventObject.hybridH5) {
        [[NSNotificationCenter defaultCenter] postNotificationName:HN_TRACK_EVENT_H5_NOTIFICATION object:nil userInfo:event];

        // 移除埋点校验中用到的事件名
        [input.eventObject.properties removeObjectForKey:kHNWebVisualEventName];

        event = input.eventObject.jsonObject;
        HNLogDebug(@"\n【track event from H5】:\n%@", event);

    } else {
        // track 事件通知
        [[NSNotificationCenter defaultCenter] postNotificationName:HN_TRACK_EVENT_NOTIFICATION object:nil userInfo:event];
        HNLogDebug(@"\n【track event】:\n%@", event);
    }

    HNEventRecord *record = [[HNEventRecord alloc] initWithEvent:event type:@"POST"];
    record.isInstantEvent = input.eventObject.isInstantEvent;
    input.record = record;
    completion(input);
}

@end
