//
// HNModuleProtocol.h
// Pods
//
// Created by hina on 2022/8/12.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNConfigOptions.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@class HNSecretKey;
@class HNConfigOptions;
@class HNBaseEventObject;

@protocol HNModuleProtocol <NSObject>

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) HNConfigOptions *configOptions;
+ (instancetype)defaultManager;

@optional
- (void)updateServerURL:(NSString *)serverURL;

@end

#pragma mark -

@protocol HNPropertyModuleProtocol <HNModuleProtocol>

@optional
@property (nonatomic, copy, readonly, nullable) NSDictionary *properties;

@end

#pragma mark -

@protocol HNOpenURLProtocol <NSObject>

- (BOOL)canHandleURL:(NSURL *)url;
- (BOOL)handleURL:(NSURL *)url;

@end

#pragma mark -

@protocol HNChannelMatchModuleProtocol <NSObject>

/// 获取事件的渠道信息
///
/// 注意：这个方法需要在 serialQueue 中调用，保证线程安全
///
/// @param event 事件名
- (NSDictionary *)channelInfoWithEvent:(NSString *)event;

@end

#pragma mark -

@protocol HNDebugModeModuleProtocol <NSObject>

/// 设置在 Debug 模式下，是否弹窗显示错误信息
/// @param isShow 是否显示
- (void)setShowDebugAlertView:(BOOL)isShow;

/// Debug 模式下，弹窗显示错误信息
/// @param message 错误信息
- (void)showDebugModeWarning:(NSString *)message;

@end

#pragma mark -

@protocol HNEncryptModuleProtocol <NSObject>

@property (nonatomic, readonly) BOOL hasSecretKey;

/// 用于远程配置回调中处理并保存密钥
/// @param encryptConfig 返回的
- (void)handleEncryptWithConfig:(NSDictionary *)encryptConfig;

/// 加密数据
/// @param obj 需要加密的 JSON 数据
/// @return 返回加密后的数据
- (nullable NSDictionary *)encryptJSONObject:(id)obj;

@end

#pragma mark -

@protocol HNDeepLinkModuleProtocol <NSObject>

/// 最新的来源渠道信息
@property (nonatomic, copy, nullable, readonly) NSDictionary *latestUtmProperties;

/// 当前 DeepLink 启动时的来源渠道信息
@property (nonatomic, copy, readonly) NSDictionary *utmProperties;

/// 清除本次 DeepLink 解析到的 utm 信息
- (void)clearUtmProperties;

@end

#pragma mark -

@protocol HNAutoTrackModuleProtocol <NSObject>

/// 触发 App 崩溃时的退出事件
- (void)trackAppEndWhenCrashed;
- (void)trackPageLeaveWhenCrashed;

@end

#pragma mark -

@protocol HNJavaScriptBridgeModuleProtocol <NSObject>

- (nullable NSString *)javaScriptSource;
@end

@protocol HNRemoteConfigModuleProtocol <NSObject>

/// 重试远程配置请求
/// @param isForceUpdate 是否强制请求最新的远程配置
- (void)retryRequestRemoteConfigWithForceUpdateFlag:(BOOL)isForceUpdate;

/// 事件对象是否被远程控制忽略
/// @param obj 事件对象
- (BOOL)isIgnoreEventObject:(HNBaseEventObject *)obj;

/// 是否禁用 SDK
- (BOOL)isDisableSDK;

@end

@protocol HNVisualizedModuleProtocol <NSObject>

/// 元素相关属性
/// @param view 需要采集的 view
- (nullable NSDictionary *)propertiesWithView:(id)view;

#pragma mark visualProperties

/// 采集元素自定义属性
/// @param view 触发事件的元素
/// @param completionHandler 采集完成回调
- (void)visualPropertiesWithView:(id)view completionHandler:(void (^)(NSDictionary *_Nullable visualProperties))completionHandler;

/// 根据配置，采集属性
/// @param propertyConfigs 自定义属性配置
/// @param completionHandler 采集完成回调
- (void)queryVisualPropertiesWithConfigs:(NSArray <NSDictionary *>*)propertyConfigs completionHandler:(void (^)(NSDictionary *_Nullable properties))completionHandler;

@end

NS_ASSUME_NONNULL_END
