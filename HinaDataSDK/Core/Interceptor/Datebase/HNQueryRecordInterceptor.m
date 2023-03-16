//
// HNQueryRecordInterceptor.m
// HinaDataSDK
//
// Created by  hina on 2022/5/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNQueryRecordInterceptor.h"
#import "HNRepeatFlushInterceptor.h"

@interface HNConfigOptions ()

@property (nonatomic) HinaDataDebugMode debugMode;

@end

@implementation HNQueryRecordInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {

    // 查询数据
    NSInteger queryCount = input.configOptions.debugMode != HinaDataDebugOff ? 1 : 50;
    NSArray<HNEventRecord *> *records = [self.eventStore selectRecords:queryCount isInstantEvent:input.isInstantEvent];
    if (records.count == 0) {
        input.state = HNFlowStateStop;
    } else {
        input.records = records;
    }

    return completion(input);
}

@end
