//
// HNRemoteConfigOperator.h
// HinaDataSDK
//
// Created by hina on 2022/11/1.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNRemoteConfigModel.h"
#import "HinaDataSDK+Private.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HNRemoteConfigOperatorProtocol <NSObject>

@optional

/// 生效本地的远程配置
- (void)enableLocalRemoteConfig;

/// 尝试请求远程配置
- (void)tryToRequestRemoteConfig;

/// 删除远程配置请求
- (void)cancelRequestRemoteConfig;

/// 重试远程配置请求
/// @param isForceUpdate 是否强制请求最新的远程配置
- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate;

/// 处理远程配置的 URL
/// @param url 远程配置的 URL
- (BOOL)handleRemoteConfigURL:(NSURL *)url;

@end

/// 远程配置处理基类
@interface HNRemoteConfigOperator : NSObject <HNRemoteConfigOperatorProtocol>

@property (nonatomic, strong) HNConfigOptions *configOptions;
@property (atomic, strong) HNRemoteConfigModel *model;
@property (nonatomic, assign, readonly) BOOL isDisableSDK;
/// 控制 AutoTrack 采集方式（-1 表示不修改现有的 AutoTrack 方式；0 代表禁用所有的 AutoTrack；其他 1～15 为合法数据）
@property (nonatomic, assign, readonly) NSInteger autoTrackMode;
@property (nonatomic, copy, readonly) NSString *project;

/// 初始化远程配置处理基类
/// @param configOptions 初始化 SDK 的配置参数
/// @param model 输入的远程配置模型
/// @return 远程配置处理基类的实例
- (instancetype)initWithConfigOptions:(HNConfigOptions *)configOptions remoteConfigModel:(nullable HNRemoteConfigModel *)model;

/// 是否在事件黑名单中
/// @param event 输入的事件名
/// @return 是否在事件黑名单中
- (BOOL)isBlackListContainsEvent:(nullable NSString *)event;

/// 请求远程配置
/// @param isForceUpdate 是否请求最新的配置
/// @param completion 请求结果的回调
- (void)requestRemoteConfigWithForceUpdate:(BOOL)isForceUpdate completion:(void (^)(BOOL success, NSDictionary<NSString *, id> * _Nullable config))completion;

/// 从请求远程配置的返回结果中获取远程配置相关内容
/// @param config 请求远程配置的返回结果
/// @return 远程配置相关内容
- (NSDictionary<NSString *, id> *)extractRemoteConfig:(NSDictionary<NSString *, id> *)config;

/// 从请求远程配置的返回结果中获取加密相关内容
/// @param config 请求远程配置的返回结果
/// @return 加密相关内容
- (NSDictionary<NSString *, id> *)extractEncryptConfig:(NSDictionary<NSString *, id> *)config;

/// 触发 H_AppRemoteConfigChanged 事件
/// @param remoteConfig 事件中的属性
- (void)trackAppRemoteConfigChanged:(NSDictionary<NSString *, id> *)remoteConfig;

/// 根据传入的内容生效远程配置
/// @param config 远程配置的内容
- (void)enableRemoteConfig:(NSDictionary *)config;

@end

NS_ASSUME_NONNULL_END
