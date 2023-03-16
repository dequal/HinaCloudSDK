//
// HNBaseEventObject.h
// HinaDataSDK
//
// Created by hina on 2022/4/13.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNEventLibObject.h"
#import "HNPropertyValidator.h"
#import "HNPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNBaseEventObject : NSObject <HNEventPropertyValidatorProtocol, HNPropertyPluginEventFilter>

/// 未登录时: 匿名 ID; 登录后: 登录 ID
@property (nonatomic, copy) NSString *distinctId;

/// 登录 ID
@property (nonatomic, copy) NSString *loginId;

/// 匿名 ID
@property (nonatomic, copy) NSString *anonymousId;

/// 登录事件中的 匿名 ID
@property (nonatomic, copy) NSString *originalId;

/// 事件名称
@property (nonatomic, copy) NSString *eventId;

/// 通过 eventId 转换的 event
@property (nonatomic, copy, readonly) NSString *event;

/// 事件类型
@property (nonatomic, assign) HNEventType type;

/// lib 信息
@property (nonatomic, strong) HNEventLibObject *lib;

/// 时间戳
@property (nonatomic, assign) UInt64 time;

/// 事件 id
@property (nonatomic, strong) NSNumber *trackId;

/// 项目
@property (nonatomic, copy) NSString *project;

/// token
@property (nonatomic, copy) NSString *token;

/// 事件属性
@property (nonatomic, strong) NSMutableDictionary *properties;

// 自定义属性，暂未开放
//@property (nonatomic, strong) NSDictionary *customProperties;

/// 开机时间，用于统计事件时长
@property (nonatomic, assign) UInt64 currentSystemUpTime;

/// 用于记录动态公共属性, 动态公共属性需要在 serialQueue 队列外获取
//@property (nonatomic, strong) NSDictionary *dynamicSuperProperties;

/// ID-Mapping 3.0 新增identities
@property (nonatomic, strong) NSDictionary *identities;

/// 忽略远程控制，强制上报，默认为 NO
@property (nonatomic, assign, getter=isIgnoreRemoteConfig) BOOL ignoreRemoteConfig;

/// 是否为 H5 打通事件
@property (nonatomic, assign) BOOL hybridH5;

/// is instant event or not, default is NO
@property (nonatomic, assign) BOOL isInstantEvent;

- (instancetype)initWithH5Event:(NSDictionary *)event;

/// 校验事件名称
/// @param error 错误信息
- (void)validateEventWithError:(NSError **)error;

/// 校验是否是登录事件
- (BOOL)isSignUp;

/// 生成最终的事件信息
- (NSMutableDictionary *)jsonObject;

+ (HNEventType)eventTypeWithType:(NSString *)type;
+ (NSString *)typeWithEventType:(HNEventType)type;

@end

NS_ASSUME_NONNULL_END
