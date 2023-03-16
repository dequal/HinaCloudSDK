//
// HNDeepLinkProcessor.h
// HinaDataSDK
//
// Created by hina on 2022/12/13.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HinaDataSDK+DeepLink.h"
#import "HNTrackEventObject.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^HNDeepLinkCompletion)(HNDeepLinkObject *object);

@protocol HNDeepLinkProcessorDelegate <NSObject>

/**
@abstract
回传 DeepLink 解析到的渠道信息，并接收客户设置的 DeepLink Completion 函数

@param channels DeepLink 唤起时解析到的渠道信息，H_utm_content 等内容
@param latestChannels 最后一次 DeepLink 唤起时解析到的渠道信息，H_latest_utm_content 等内容
@param isDeferredDeepLink 是否为 Deferred DeepLink 场景，处理 completion 兼容场景
*/
- (HNDeepLinkCompletion)sendChannels:(NSDictionary *_Nullable)channels latestChannels:(NSDictionary *_Nullable)latestChannels isDeferredDeepLink:(BOOL)isDeferredDeepLink;

@end

@interface HNDeepLinkProcessor : NSObject

/// 处理回调函数代理对象
@property (nonatomic, weak) id<HNDeepLinkProcessorDelegate> delegate;

@property (nonatomic, copy) NSURL *URL;

@property (nonatomic, strong) NSSet *customChannelKeys;

/// 子类重写，处理器支持的 URL 格式
+ (BOOL)isValidURL:(NSURL *)url customChannelKeys:(NSSet *)customChannelKeys;

/// 当前 Processor 是否可以通过短链 URL 唤起，默认不支持
- (BOOL)canWakeUp;

/// 开始处理 DeepLink 后续逻辑
- (void)startWithProperties:(NSDictionary *_Nullable)properties;

/// 触发 H_AppDeeplinkLaunch 事件
- (void)trackDeepLinkLaunch:(NSDictionary *)properties;

/// 触发 H_AppDeeplinkMatchedResult 事件
- (void)trackDeepLinkMatchedResult:(NSDictionary *)properties;

/// 获取渠道归因参数
- (NSDictionary *)acquireChannels:(NSDictionary *)dictionary;

/// 获取最后一次的渠道归因参数
- (NSDictionary *)acquireLatestChannels:(NSDictionary *)dictionary;

/// 设备信息
- (NSString *)appInstallSource;

@end

@interface HNDeepLinkProcessorFactory : NSObject

/**
 @abstract
 根据 URL 规则生成不同的 DeepLink Processor

 @param url 唤起的 URL
 @param customChannelKeys 自定义渠道参数键值
 @return DeepLink 处理器
 */
+ (HNDeepLinkProcessor *)processorFromURL:(NSURL *_Nullable)url customChannelKeys:(NSSet *)customChannelKeys;

@end

NS_ASSUME_NONNULL_END
