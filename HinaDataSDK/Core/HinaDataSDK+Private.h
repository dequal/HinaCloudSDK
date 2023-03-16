//
// HinaDataSDK_priv.h
// HinaDataSDK
//
// Created by hina on 2022/8/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#ifndef HinaDataSDK_Private_h
#define HinaDataSDK_Private_h
#import "HinaDataSDK.h"
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "HNNetwork.h"
#import "HNHTTPSession.h"
#import "HNTrackEventObject.h"
#import "HNAppLifecycle.h"


@interface HinaDataSDK(Private)

/**
 * @abstract
 * 返回之前所初始化好的单例
 *
 * @discussion
 * 调用这个方法之前，必须先调用 startWithConfigOptions: 。
 * 这个方法与 sharedInstance 类似，但是当远程配置关闭 SDK 时，sharedInstance 方法会返回 nil，这个方法仍然能获取到 SDK 的单例
 *
 * @return 返回的单例
 */
+ (HinaDataSDK *)sdkInstance;

+ (NSString *)libVersion;

#pragma mark - method

/// 触发事件
/// @param object 事件对象
/// @param properties 事件属性
- (void)trackEventObject:(HNBaseEventObject *)object properties:(NSDictionary *)properties;

/// 准备采集动态公共属性
///
/// 需要在队列外执行
- (void)buildDynamicSuperProperties;

#pragma mark - property
@property (nonatomic, strong, readonly) HNConfigOptions *configOptions;
@property (nonatomic, strong, readonly) HNNetwork *network;
@property (nonatomic, strong, readonly) dispatch_queue_t serialQueue;

@end

/**
 HNConfigOptions 实现
 私有 property
 */
@interface HNConfigOptions()

/// 数据接收地址 serverURL
@property(atomic, copy) NSString *serverURL;

/// App 启动的 launchOptions
@property(nonatomic, strong) id launchOptions;

@property (nonatomic) HinaDataDebugMode debugMode;

@property (nonatomic, strong) NSMutableArray *storePlugins;

//忽略页面浏览时长的页面
@property  (nonatomic, copy) NSSet<Class> *ignoredPageLeaveClasses;

@property (atomic, strong) NSMutableArray<HNPropertyPlugin *> *propertyPlugins;

@end

#endif /* HinaDataSDK_priv_h */
