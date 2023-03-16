//
// HNUpdateRecordInterceptor.m
// HinaDataSDK
//
// Created by  hina on 2022/5/17.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNUpdateRecordInterceptor.h"
#import "HNFileStorePlugin.h"
#import "HNEventStore.h"

@implementation HNUpdateRecordInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.records);

    // 更新状态
    // 获取查询到的数据的 id
    NSMutableArray *recordIDs = [NSMutableArray arrayWithCapacity:input.records.count];
    for (HNEventRecord *record in input.records) {
        [recordIDs addObject:record.recordID];
    }
    input.recordIDs = recordIDs;

    // 更新数据状态
    [self.eventStore updateRecords:recordIDs status:HNEventRecordStatusFlush];

    return completion(input);
}

@end
