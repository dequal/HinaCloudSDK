//
// HNDynamicSuperPropertyInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDynamicSuperPropertyInterceptor.h"
#import "HNDynamicSuperPropertyPlugin.h"
#import "HNPropertyPluginManager.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"


@implementation HNDynamicSuperPropertyInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {

    // 当前已经切换到了 serialQueue，说明外部已执行采集动态公共属性 block，不再重复执行
    dispatch_queue_t serialQueue = HinaDataSDK.sdkInstance.serialQueue;
    if ( hinadata_is_same_queue(serialQueue)) {
        return completion(input);
    }

    HNDynamicSuperPropertyPlugin *propertyPlugin = HNDynamicSuperPropertyPlugin.sharedDynamicSuperPropertyPlugin;
    // 动态公共属性，需要在 serialQueue 外获取内容，在队列内添加
    [propertyPlugin buildDynamicSuperProperties];
    completion(input);
}

@end
