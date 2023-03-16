//
// HNSerialQueueInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNSerialQueueInterceptor.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"

NSString * const kHNSerialQueueSync = @"sync";

@interface HNSerialQueueInterceptor ()

@property (nonatomic, assign) BOOL isSync;

@end

@implementation HNSerialQueueInterceptor

+ (instancetype)interceptorWithParam:(NSDictionary *)param {
    HNSerialQueueInterceptor *interceptor = [[HNSerialQueueInterceptor alloc] init];
    if ([param[kHNSerialQueueSync] isKindOfClass:NSNumber.class]) {
        interceptor.isSync = [param[kHNSerialQueueSync] boolValue];
    }
    return interceptor;
}

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    dispatch_queue_t serialQueue = HinaDataSDK.sdkInstance.serialQueue;
    if (hinadata_is_same_queue(serialQueue)) {
        return completion(input);
    }

    if (self.isSync) {
        dispatch_sync(serialQueue, ^{
            completion(input);
        });
    } else {
        dispatch_async(serialQueue, ^{
            completion(input);
        });
    }
}

@end
