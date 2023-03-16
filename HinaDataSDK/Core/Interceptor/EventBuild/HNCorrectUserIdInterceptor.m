//
// HNCorrectUserIdInterceptor.m
// HinaABTest
//
// Created by  hina on 2022/6/13.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNCorrectUserIdInterceptor.h"
#import "HNValidator.h"

#pragma mark userId
// A/B Testing 触发 H_ABTestTrigge 事件修正属性
static NSString *const kHNBLoginId = @"sab_loginId";
static NSString *const kHNBDistinctId = @"sab_distinctId";
static NSString *const kHNBAnonymousId = @"sab_anonymousId";
static NSString *const kHNBTriggerEventName = @"H_ABTestTrigger";


// SF 触发 H_PlanPopupDisplay 事件修正属性
static NSString * const kSFDistinctId = @"sf_distinctId";
static NSString * const kSFLoginId = @"sf_loginId";
static NSString * const kSFAnonymousId = @"sf_anonymousId";
static NSString * const SFPlanPopupDisplayEventName = @"H_PlanPopupDisplay";


@implementation HNCorrectUserIdInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);
    if (!input.properties) {
        return completion(input);
    }
    
    HNBaseEventObject *object = input.eventObject;
    NSString *eventName = object.event;
    NSMutableDictionary *properties = [input.properties mutableCopy];
    
    // item 操作，不采集用户 Id 信息
    BOOL isNeedCorrectUserId = [eventName isEqualToString:kHNBTriggerEventName] || [eventName isEqualToString:SFPlanPopupDisplayEventName];
    if (![HNValidator isValidString:eventName] || !isNeedCorrectUserId) {
        return completion(input);
    }
    
    // H_ABTestTrigger 事件修正
    if ([eventName isEqualToString:kHNBTriggerEventName]) {
        // 修改 loginId, distinctId,anonymousId
        if (properties[kHNBLoginId]) {
            object.loginId = properties[kHNBLoginId];
            [properties removeObjectForKey:kHNBLoginId];
        }
        
        if (properties[kHNBDistinctId]) {
            object.distinctId = properties[kHNBDistinctId];
            [properties removeObjectForKey:kHNBDistinctId];
        }
        
        if (properties[kHNBAnonymousId]) {
            object.anonymousId = properties[kHNBAnonymousId];
            [properties removeObjectForKey:kHNBAnonymousId];
        }
    }
    
    // H_PlanPopupDisplay 事件修正
    if ([eventName isEqualToString:SFPlanPopupDisplayEventName]) {
        // 修改 loginId, distinctId,anonymousId
        if (properties[kSFLoginId]) {
            object.loginId = properties[kSFLoginId];
            [properties removeObjectForKey:kSFLoginId];
        }
        
        if (properties[kSFDistinctId]) {
            object.distinctId = properties[kSFDistinctId];
            [properties removeObjectForKey:kSFDistinctId];
        }
        
        if (properties[kSFAnonymousId]) {
            object.anonymousId = properties[kSFAnonymousId];
            [properties removeObjectForKey:kSFAnonymousId];
        }
    }
    
    input.properties = [properties copy];
    completion(input);
}

@end
