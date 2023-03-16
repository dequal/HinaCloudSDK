//
// HNIdentifier.h
// HinaDataSDK
//
// Created by hina on 2022/2/17.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNConstants.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kHNIdentitiesLoginId;
extern NSString * const kHNLoginIdSpliceKey;

@interface HNIdentifier : NSObject

/// 用户的登录 Id
@property (nonatomic, copy, readonly) NSString *loginId;

/// 匿名 Id（设备 Id）：IDFA -> IDFV -> UUID
@property (nonatomic, copy, readonly) NSString *anonymousId;

/// 唯一用户标识：loginId -> 设备 Id
@property (nonatomic, copy, readonly) NSString *distinctId;

/// ID-Mapping 3.0 业务 ID，当前所有处理逻辑都是在的 serialQueue 中处理
@property (nonatomic, copy, readonly) NSDictionary *identities;

/// 自定义的 loginIDKey
@property (nonatomic, copy, readonly) NSString *loginIDKey;

/**
 初始化方法

 @param queue 一个全局队列
 @return 初始化对象
 */
- (instancetype)initWithQueue:(dispatch_queue_t)queue;

/**
 自定义匿名 Id（设备 Id）

 @param anonymousId 匿名 Id（设备 Id）
 @return 自定义匿名 ID 结果

 */
- (BOOL)identify:(NSString *)anonymousId;

/**
 重置匿名 Id
 */
- (void)resetAnonymousId;

#pragma mark - Login
/**
检查登录时参数的合法性

 @param key 设置的 loginIDKey
 @param value 设置的 loginId
 @return 合法性结果
*/
- (BOOL)isValidForLogin:(NSString *)key value:(NSString *)value;

/**
 通过登录接口设置 loginIDKey 和 loginId

 @param key 新的 loginIDKey
 @param loginId 新的 loginId
 */
- (void)loginWithKey:(NSString *)key loginId:(NSString *)loginId;

/**
 通过退出登录接口删除本地的 loginId
 */
- (void)logout;

#pragma mark - Device ID
/**
 获取设备的 IDFA

 @return idfa
 */
+ (NSString *)idfa API_UNAVAILABLE(macos);

/**
 获取设备的 IDFV

 @return idfv
 */
+ (NSString *)idfv API_UNAVAILABLE(macos);

/**
 生成匿名 Id（设备 Id）：IDFA -> IDFV -> UUID

 @return 匿名 Id（设备 Id）
 */
+ (NSString *)hardwareID;

#pragma mark - Identities

/// 检查绑定业务 ID 是否有效，用于触发事件前判断
- (BOOL)isValidForBind:(NSString *)key value:(NSString *)value;

/// 检查解绑业务 ID 是否有效，用于触发事件前判断
- (BOOL)isValidForUnbind:(NSString *)key value:(NSString *)value;

/// 绑定业务 ID，需要在 serialQueue 中调用
- (void)bindIdentity:(NSString *)key value:(NSString *)value;

/// 解绑业务 ID，需要在 serialQueue 中调用
- (void)unbindIdentity:(NSString *)key value:(NSString *)value;

/// 获取当前事件的业务 ID
- (NSDictionary *)identitiesWithEventType:(HNEventType)eventType;

/// 用于合并 H5 传过来的业务 ID
- (NSDictionary *)mergeH5Identities:(NSDictionary *)identities eventType:(HNEventType)eventType;

@end

NS_ASSUME_NONNULL_END
