//
// HNDeleteRecordInterceptor.m
// HinaDataSDK
//
// Created by  hina on 2022/5/17.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDeleteRecordInterceptor.h"

@implementation HNDeleteRecordInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    // 从库中读出，准备上传时设置 recordIDs
    if (!input.recordIDs) {
        return completion(input);
    }

    // 上传完成
    if (input.flushSuccess) {
        [self.eventStore deleteRecords:input.recordIDs];

        if (self.eventStore.count == 0) {
            input.state = HNFlowStateStop;
        }
    } else {
        [self.eventStore updateRecords:input.recordIDs status:HNEventRecordStatusNone];
        input.state = HNFlowStateStop;
    }
    return completion(input);
}

@end
