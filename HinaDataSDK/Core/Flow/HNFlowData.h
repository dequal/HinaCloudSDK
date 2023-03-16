//
// HNFlowData.h
// HinaDataSDK
//
// Created by hina on 2022/2/17.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNConfigOptions.h"
#import "HNBaseEventObject.h"

@class HNIdentifier, HNEventRecord, HNFlowData;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HNFlowState) {
    HNFlowStateNext,
    HNFlowStateStop,
    HNFlowStateError,
};
typedef void(^HNFlowDataCompletion)(HNFlowData *output);

@interface HNFlowData : NSObject

@property (nonatomic) HNFlowState state;

@property (nonatomic, copy, nullable) NSString *message;

@property (nonatomic, strong) HNConfigOptions *configOptions;

@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *param;

- (instancetype)init;

@end

#pragma mark -

@interface HNFlowData (HNParam)

#pragma mark - build
@property (nonatomic, strong, nullable) NSDictionary *properties;
@property (nonatomic, strong, nullable) HNBaseEventObject *eventObject;

/// ID-Mapping 相关
@property (nonatomic, strong, nullable) HNIdentifier *identifier;

/// mark event is instant or not
@property (nonatomic,assign) BOOL isInstantEvent;

#pragma mark - store

/// 单条数据记录
///
/// eventObject 转 json 后，构建 record
@property (nonatomic, strong, nullable) HNEventRecord *record;

@property (nonatomic, strong, nullable) NSArray<HNEventRecord *> *records;
@property (nonatomic, strong, nullable) NSArray<NSString *> *recordIDs;

#pragma mark - flush
@property (nonatomic, copy, nullable) NSString *json;
@property (nonatomic, strong, nullable) NSData *HTTPBody;
@property (nonatomic, assign) BOOL flushSuccess;
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, copy, nullable) NSString *cookie;
@property (nonatomic, assign) NSInteger repeatCount;

@end

NS_ASSUME_NONNULL_END
