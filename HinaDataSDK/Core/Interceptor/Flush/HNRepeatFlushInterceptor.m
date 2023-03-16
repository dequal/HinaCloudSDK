//
// HNRepeatFlushInterceptor.m
// HinaDataSDK
//
// Created by  hina on 2022/5/31.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNRepeatFlushInterceptor.h"
#import "HNFlowManager.h"

static NSInteger const kHNFlushMaxRepeatCount = 100;

@interface HNRepeatFlushInterceptor ()
@end

@implementation HNRepeatFlushInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    if (input.repeatCount >= kHNFlushMaxRepeatCount) {
        // 到达最大次数，暂停上传
        input.state = HNFlowStateStop;
        return completion(input);
    }

    HNFlowData *inputData = [[HNFlowData alloc] init];
    inputData.cookie = input.cookie;
    inputData.repeatCount = input.repeatCount + 1;
    inputData.isInstantEvent = input.isInstantEvent;
    // 当前已处于 serialQueue，不必再切队列
    [HNFlowManager.sharedInstance startWithFlowID:kHNFlushFlowId input:inputData completion:^(HNFlowData * _Nonnull output) {
        completion(output);
    }];
}

@end
