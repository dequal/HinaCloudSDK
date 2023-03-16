//
// HNInsertRecordInterceptor.m
// HinaDataSDK
//
// Created by  hina on 2022/5/17.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNInsertRecordInterceptor.h"

@interface HNConfigOptions ()

@property (nonatomic) HinaDataDebugMode debugMode;

@end


@implementation HNInsertRecordInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.record);
    
    [self.eventStore insertRecord:input.record];

    // 不满足 flush 条件，流程结束
    // 判断本地数据库中未上传的数量
    if (!input.eventObject.isSignUp &&
        [self.eventStore recordCountWithStatus:HNEventRecordStatusNone] <= input.configOptions.flushBulkSize &&
        input.configOptions.debugMode == HinaDataDebugOff && !input.isInstantEvent) {
        input.state = HNFlowStateStop;
    }
    return completion(input);
}

@end
