//
// HNJavaScriptBridgeManager.h
// HinaDataSDK
//
// Created by hina on 2022/3/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "HNModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNJavaScriptBridgeManager : NSObject <WKScriptMessageHandler, HNModuleProtocol, HNJavaScriptBridgeModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) HNConfigOptions *configOptions;

- (void)addScriptMessageHandlerWithWebView:(WKWebView *)webView;

@end


/**
 * @abstract
 * App 调用 JS 方法的类型。
 *
 * @discussion
 * 调用 JS 方法类型枚举
 */
typedef NS_ENUM(NSInteger, HNJavaScriptCallJSType) {
    /// 进入可视化扫码模式通知 JS
    HNJavaScriptCallJSTypeVisualized,
    /// 检测是否集成 JS SDK
    HNJavaScriptCallJSTypeCheckJSSDK,
    /// 更新自定义属性配置
    HNJavaScriptCallJSTypeUpdateVisualConfig,
    /// 获取 App 内嵌 H5 采集的自定义属性
    HNJavaScriptCallJSTypeWebVisualProperties
};

/// 打通写入 serverURL
extern NSString * const kHNJSBridgeServerURL;

/// 可视化通知已进入扫码模式
extern NSString * const kHNJSBridgeVisualizedMode;

/// js 方法调用
extern NSString * const kHNJSBridgeCallMethod;

/// 构建 js 相关 bridge 和变量
@interface HNJavaScriptBridgeBuilder : NSObject

#pragma mark 注入 js
/// 注入打通bridge，并设置 serverURL
/// @param serverURL 数据接收地址
+ (nullable NSString *)buildJSBridgeWithServerURL:(NSString *)serverURL;

/// 注入可视化 bridge，并设置扫码模式
/// @param isVisualizedMode 是否为可视化扫码模式
+ (nullable NSString *)buildVisualBridgeWithVisualizedMode:(BOOL)isVisualizedMode;

/// 注入自定义属性 bridge，配置信息
/// @param originalConfig 配置信息原始 json
+ (nullable NSString *)buildVisualPropertyBridgeWithVisualConfig:(NSDictionary *)originalConfig;

#pragma mark JS 调用

/// js 方法调用
/// @param type 调用类型
/// @param object 传参
+ (nullable NSString *)buildCallJSMethodStringWithType:(HNJavaScriptCallJSType)type jsonObject:(nullable id)object;

@end

NS_ASSUME_NONNULL_END
