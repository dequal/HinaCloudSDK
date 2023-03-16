//
// HNEventRecord.m
// HinaDataSDK
//
// Created by hina on 2022/6/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNEventRecord.h"
#import "HNJSONUtil.h"
#import "HNValidator.h"

static NSString * const HNEncryptRecordKeyEKey = @"ekey";
static NSString * const HNEncryptRecordKeyPayloads = @"payloads";
static NSString * const HNEncryptRecordKeyPayload = @"payload";

@implementation HNEventRecord {
    NSMutableDictionary *_event;
}

static long recordIndex = 0;

- (instancetype)initWithEvent:(NSDictionary *)event type:(NSString *)type {
    if (self = [super init]) {
        _recordID = [NSString stringWithFormat:@"HN_%ld", recordIndex];
        _event = [event mutableCopy];
        _type = type;

        _encrypted = _event[HNEncryptRecordKeyEKey] != nil;

        // 事件数据插入自定义的 ID 自增，这个 ID 在入库之前有效，入库之后数据库会生成新的 ID
        recordIndex++;
    }
    return self;
}

- (instancetype)initWithRecordID:(NSString *)recordID content:(NSString *)content {
    if (self = [super init]) {
        _recordID = recordID;

        NSMutableDictionary *eventDic = [HNJSONUtil JSONObjectWithString:content options:NSJSONReadingMutableContainers];
        if (eventDic) {
            _event = eventDic;
            _encrypted = _event[HNEncryptRecordKeyEKey] != nil;
        }
    }
    return self;
}

- (NSString *)content {
    return [HNJSONUtil stringWithJSONObject:self.event];
}

- (BOOL)isValid {
    return self.event.count > 0;
}

- (NSString *)flushContent {
    if (![self isValid]) {
        return nil;
    }

    // 需要先添加 flush time，再进行 json 拼接
    UInt64 time = [[NSDate date] timeIntervalSince1970] * 1000;
    _event[self.encrypted ? @"flush_time" : @"_flush_time"] = @(time);
    
    return self.content;
}

- (NSString *)ekey {
    return _event[HNEncryptRecordKeyEKey];
}

- (void)setSecretObject:(NSDictionary *)obj {
    if (![HNValidator isValidDictionary:obj]) {
        return;
    }
    [_event removeAllObjects];
    [_event addEntriesFromDictionary:obj];

    _encrypted = YES;
}

- (void)removePayload {
    if (!_event[HNEncryptRecordKeyPayload]) {
        return;
    }
    _event[HNEncryptRecordKeyPayloads] = [NSMutableArray arrayWithObject:_event[HNEncryptRecordKeyPayload]];
    [_event removeObjectForKey:HNEncryptRecordKeyPayload];
}

- (BOOL)mergeSameEKeyRecord:(HNEventRecord *)record {
    if (![self.ekey isEqualToString:record.ekey]) {
        return NO;
    }
    [(NSMutableArray *)_event[HNEncryptRecordKeyPayloads] addObject:record.event[HNEncryptRecordKeyPayload]];
    return YES;
}

@end
