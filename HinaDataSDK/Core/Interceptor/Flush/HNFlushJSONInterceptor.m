//
// HNFlushJSONInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/11.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNFlushJSONInterceptor.h"
#import "HNJSONUtil.h"
#import "HNEventRecord.h"

@interface HNConfigOptions ()

@property (nonatomic, assign) BOOL enableEncrypt;

@end

#pragma mark -

@implementation HNFlushJSONInterceptor

// 1. 先完成这一系列 Json 字符串的拼接
- (NSString *)buildFlushJSONStringWithEventRecords:(NSArray<HNEventRecord *> *)records {
    NSMutableArray *contents = [NSMutableArray arrayWithCapacity:records.count];
    for (HNEventRecord *record in records) {
        NSString *flushContent = [record flushContent];
        if (flushContent) {
            [contents addObject:flushContent];
        }
    }
    return [NSString stringWithFormat:@"[%@]", [contents componentsJoinedByString:@","]];
}

- (NSString *)buildFlushEncryptJSONStringWithEventRecords:(NSArray<HNEventRecord *> *)records {
    // 初始化用于保存合并后的事件数据
    NSMutableArray *encryptRecords = [NSMutableArray arrayWithCapacity:records.count];
    // 用于保存当前存在的所有 ekey
    NSMutableArray *ekeys = [NSMutableArray arrayWithCapacity:records.count];
    for (HNEventRecord *record in records) {
        NSInteger index = [ekeys indexOfObject:record.ekey];
        if (index == NSNotFound) {
            [record removePayload];
            [encryptRecords addObject:record];

            [ekeys addObject:record.ekey];
        } else {
            [encryptRecords[index] mergeSameEKeyRecord:record];
        }
    }
    return [self buildFlushJSONStringWithEventRecords:encryptRecords];
}

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    NSParameterAssert(input.records.count > 0);

    // 判断是否加密数据
    BOOL isEncrypted = input.configOptions.enableEncrypt && input.records.firstObject.isEncrypted;
    input.json = isEncrypted ? [self buildFlushEncryptJSONStringWithEventRecords:input.records] : [self buildFlushJSONStringWithEventRecords:input.records];
    completion(input);
}

@end
