//
// HNVisualizedSnapshotMessage.h
// HinaDataSDK
//
// Created by hina on 2022/9/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "HNVisualizedAbstractMessage.h"

@class HNObjectSerializerConfig;

extern NSString *const HNVisualizedSnapshotRequestMessageType;

#pragma mark -- Snapshot Request

@interface HNVisualizedSnapshotRequestMessage : HNVisualizedAbstractMessage

+ (instancetype)message;

@property (nonatomic, readonly) HNObjectSerializerConfig *configuration;

@end

#pragma mark -- Snapshot Response

@interface HNVisualizedSnapshotResponseMessage : HNVisualizedAbstractMessage

+ (instancetype)message;

@property (nonatomic, strong) UIImage *screenshot;
@property (nonatomic, copy) NSDictionary *serializedObjects;

/// 数据包的 hash 标识（默认为截图 hash，可能包含 H5 页面元素信息、event_debug、log_info 等）
@property (nonatomic, copy) NSString *payloadHash;

/// 原始截图 hash
@property (nonatomic, copy, readonly) NSString *originImageHash;

/// 调试事件
@property (nonatomic, copy) NSArray <NSDictionary *> *debugEvents;

/// 诊断日志信息
@property (nonatomic, copy) NSArray <NSDictionary *> *logInfos;
@end
