//
// HNFlowManager.h
// HinaDataSDK
//
// Created by hina on 2022/2/17.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNConfigOptions.h"
#import "HNFlowObject.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kHNTrackFlowId;
extern NSString * const kHNFlushFlowId;

@interface HNFlowManager : NSObject

@property (nonatomic, strong) HNConfigOptions *configOptions;

+ (instancetype)sharedInstance;

/// 加载 flow
///
/// 解析 json 配置创建 flow 并注册
- (void)loadFlows;

- (void)registerFlow:(HNFlowObject *)flow;
- (void)registerFlows:(NSArray<HNFlowObject *> *)flows;

- (HNFlowObject *)flowForID:(NSString *)flowID;

- (void)startWithFlowID:(NSString *)flowID input:(HNFlowData *)input completion:(nullable HNFlowDataCompletion)completion;
- (void)startWithFlow:(HNFlowObject *)flow input:(HNFlowData *)input completion:(nullable HNFlowDataCompletion)completion;

@end

NS_ASSUME_NONNULL_END
