//
// HNCanFlushInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNCanFlushInterceptor.h"
#import "HinaDataSDK+Private.h"
#import "HNNetworkInfoPropertyPlugin.h"

@implementation HNCanFlushInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    
    if (input.configOptions.serverURL.length == 0) {
        input.state = HNFlowStateStop;
    }
    
    // 判断当前网络类型是否符合同步数据的网络策略
    HNNetworkInfoPropertyPlugin *carrierPlugin = [[HNNetworkInfoPropertyPlugin alloc] init];
    if (!([carrierPlugin currentNetworkTypeOptions] & input.configOptions.flushNetworkPolicy)) {
        input.state = HNFlowStateStop;
    }
    completion(input);
}

@end
