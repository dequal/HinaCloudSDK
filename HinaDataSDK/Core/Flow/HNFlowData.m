//
// HNFlowData.m
// HinaDataSDK
//
// Created by hina on 2022/2/17.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNFlowData.h"
#import "HNIdentifier.h"
#import "HNConstants+Private.h"

static NSString * const kHNFlowDataEventObject = @"event_object";
static NSString * const kHNFlowDataIdentifier = @"identifier";

/// 单条数据记录
static NSString * const kHNFlowDataRecord = @"record";
static NSString * const kHNFlowDataJSON = @"json";
static NSString * const kHNFlowDataHTTPBody = @"http_body";
static NSString * const kHNFlowDataRecords = @"records";
static NSString * const kHNFlowDataRecordIDs = @"record_ids";

static NSString * const kHNFlowDataProperties = @"attr";
static NSString * const kHNFlowDataFlushSuccess = @"flush_success";
static NSString * const kHNFlowDataStatusCode = @"status_code";
static NSString * const kHNFlowDataFlushCookie = @"flush_cookie";
static NSString * const kHNFlowDataRepeatCount = @"repeat_count";

@implementation HNFlowData

- (instancetype)init {
    self = [super init];
    if (self) {
        _param = [NSMutableDictionary dictionary];
    }
    return self;
}

@end


#pragma mark -

@implementation HNFlowData (HNParam)

- (void)setParamWithKey:(NSString *)key value:(id _Nullable)value {
    if (value == nil) {
        [self.param removeObjectForKey:key];
    } else {
        self.param[key] = value;
    }
}

- (void)setRecord:(HNEventRecord *)record {
    [self setParamWithKey:kHNFlowDataRecord value:record];
}

- (HNEventRecord *)record {
    return self.param[kHNFlowDataRecord];

}

- (void)setJson:(NSString *)json {
    [self setParamWithKey:kHNFlowDataJSON value:json];
}

- (NSString *)json {
    return self.param[kHNFlowDataJSON];
}

- (void)setHTTPBody:(NSData *)HTTPBody {
    [self setParamWithKey:kHNFlowDataHTTPBody value:HTTPBody];
}

- (NSData *)HTTPBody {
    return self.param[kHNFlowDataHTTPBody];
}

- (void)setRecords:(NSArray<HNEventRecord *> *)records {
    [self setParamWithKey:kHNFlowDataRecords value:records];
}

- (NSArray<HNEventRecord *> *)records {
    return self.param[kHNFlowDataRecords];
}

- (void)setRecordIDs:(NSArray<NSString *> *)recordIDs {
    [self setParamWithKey:kHNFlowDataRecordIDs value:recordIDs];
}

- (NSArray<NSString *> *)recordIDs {
    return self.param[kHNFlowDataRecordIDs];
}

- (void)setEventObject:(HNBaseEventObject *)eventObject {
    [self setParamWithKey:kHNFlowDataEventObject value:eventObject];
    self.isInstantEvent = eventObject.isInstantEvent;
}

- (HNBaseEventObject *)eventObject {
    return self.param[kHNFlowDataEventObject];
}

- (void)setIdentifier:(HNIdentifier *)identifier {
    [self setParamWithKey:kHNFlowDataIdentifier value:identifier];
}

- (HNIdentifier *)identifier {
    return self.param[kHNFlowDataIdentifier];
}

- (void)setProperties:(NSDictionary *)properties {
    [self setParamWithKey:kHNFlowDataProperties value:properties];
}

- (NSDictionary *)properties {
    return self.param[kHNFlowDataProperties];
}

- (void)setFlushSuccess:(BOOL)flushSuccess {
    [self setParamWithKey:kHNFlowDataFlushSuccess value:@(flushSuccess)];
}

- (BOOL)flushSuccess {
    return [self.param[kHNFlowDataFlushSuccess] boolValue];
}

- (void)setStatusCode:(NSInteger)statusCode {
    [self setParamWithKey:kHNFlowDataStatusCode value:@(statusCode)];
}

- (NSInteger)statusCode {
    return [self.param[kHNFlowDataStatusCode] integerValue];
}

- (NSString *)cookie {
    return self.param[kHNFlowDataFlushCookie];
}

- (void)setCookie:(NSString *)cookie {
    self.param[kHNFlowDataFlushCookie] = cookie;
}

- (void)setRepeatCount:(NSInteger)repeatCount {
    [self setParamWithKey:kHNFlowDataRepeatCount value:@(repeatCount)];
}

- (NSInteger)repeatCount {
    return [self.param[kHNFlowDataRepeatCount] integerValue];
}

- (void)setIsInstantEvent:(BOOL)isInstantEvent {
    [self setParamWithKey:kHNInstantEventKey value:[NSNumber numberWithBool:isInstantEvent]];
}

-(BOOL)isInstantEvent {
    return [self.param[kHNInstantEventKey] boolValue];
}

@end
