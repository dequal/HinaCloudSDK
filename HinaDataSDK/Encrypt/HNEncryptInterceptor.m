//
// HNEncryptInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNEncryptInterceptor.h"
#import "HNModuleManager.h"
#import "HNEventRecord.h"
#import "HNConfigOptions+Encrypt.h"

#pragma mark -

@implementation HNEncryptInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions);
    NSParameterAssert(input.record || input.records);

    if (input.records) { // 读取数据库后，进行数据合并。如果开启加密，会尝试加密
        input.records = [self encryptEventRecords:input.records];
        return completion(input);
    }

    // 未开启加密
    if (!input.configOptions.enableEncrypt) {
        return completion(input);
    }

    // 入库前，单条数据加密
    if (input.record) {
        NSDictionary *obj = [HNModuleManager.sharedInstance encryptJSONObject:input.record.event];
        [input.record setSecretObject:obj];
    }

    completion(input);
}

/// 筛选加密数据，并对未加密的数据尝试加密
///
/// 即使未开启加密，也需要进行筛选，可能因为后期修改加密开关，导致本地同时存在明文和密文数据
///
/// @param records 数据
- (NSArray<HNEventRecord *> *)encryptEventRecords:(NSArray<HNEventRecord *> *)records {
    NSMutableArray *encryptRecords = [NSMutableArray arrayWithCapacity:records.count];
    for (HNEventRecord *record in records) {
        if (record.isEncrypted) {
            [encryptRecords addObject:record];
        } else {
            // 缓存数据未加密，再加密
            NSDictionary *obj = [HNModuleManager.sharedInstance encryptJSONObject:record.event];
            if (obj) {
                [record setSecretObject:obj];
                [encryptRecords addObject:record];
            }
        }
    }
    return encryptRecords.count == 0 ? records : encryptRecords;
}

@end
