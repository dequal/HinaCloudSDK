//
// HNVisualizedObjectSerializerManager.h
// HinaDataSDK
//
// Created by hina on 2022/4/23.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//


#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

/// 内嵌页面类型
typedef NS_ENUM(NSInteger, HNVisualizedPageType) {
    /// 0: 默认类型，App 原生元素
    HNVisualizedPageTypeNative = 0,
    /// 1: App 内嵌 H5 元素
    HNVisualizedPageTypeWeb,
    /// 2: Flutter 页面元素
    HNVisualizedPageTypeFlutter
};

/// 其他平台页面页面
///
/// 目前支持 App 内嵌 H5 和 Flutter
@interface HNVisualizedPageInfo : NSObject

/// 指定初始化方法，设置页面类型
///
/// @param pageType 页面类型
///
/// @return 页面信息实例对象
- (instancetype)initWithPageType:(HNVisualizedPageType)pageType NS_DESIGNATED_INITIALIZER;

/// 禁用默认初始化
- (instancetype)init NS_UNAVAILABLE;
/// 禁用默认初始化
- (instancetype)new NS_UNAVAILABLE;

/// 当前页面类型
@property (nonatomic, assign) HNVisualizedPageType pageType;

/// 页面标题
///
/// H5 页面则为 H5 标题
@property (nonatomic, copy) NSString *title;

/// 页面名称
@property (nonatomic, copy) NSString *screenName;

/// H5 url
@property (nonatomic, copy) NSString *url;

/// H5 或 Flutter 元素信息（包括可点击元素和普通元素）
@property (nonatomic, copy) NSArray *elementSources;

/// 弹框信息
/* 数据结构
key: message
value: alertInfo
 {
    "title": "弹框标题",
    "message": "App SDK 与 Web SDK 没有进行打通，请联系贵方技术人员修正 Web SDK 的配置，详细信息请查看文档。",
    "link_text": "配置文档"
    "link_url": "https://manual.hinadata.cn/sa/latest/app-h5-1573913.html"
 }
 */
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSDictionary *>* alertInfos;

/// 平台 SDK 版本号
///
/// 例如 Web JS SDK 或 Flutter SDK 版本号
@property (nonatomic, copy) NSString *platformSDKLibVersion;

/// 当前页面，注册弹框信息
- (void)registWebAlertInfos:(NSArray <NSDictionary *> *)infos;
@end



/// 可视化全埋点 viewTree 外层数据管理
@interface HNVisualizedObjectSerializerManager : NSObject

/// 获取最后一次页面浏览所在的 controller
@property (nonatomic, strong, readonly) UIViewController *lastViewScreenController;

/// 上次完整数据包的 hash 标识（默认为截图 hash，可能包含 H5 页面元素信息、event_debug、log_info 等）
@property (nonatomic, copy, readonly) NSString *lastPayloadHash;

+ (instancetype)sharedInstance;

/// 查询 H5 或 Flutter 页面信息
- (HNVisualizedPageInfo *)queryPageInfoWithType:(HNVisualizedPageType)pageType;

/// 重置解析配置
- (void)resetObjectSerializer;

#pragma mark webInfo
/// 清除 web 页面信息缓存
- (void)cleanVisualizedWebPageInfoCache;

/// 缓存可视化全埋点相关 web 信息
- (void)saveVisualizedWebPageInfoWithWebView:(WKWebView *)webview webPageInfo:(NSMutableDictionary *)pageInfo;

/// 读取当前 webView 页面信息
- (HNVisualizedPageInfo *)readWebPageInfoWithWebView:(WKWebView *)webView;

/// 进入 web 页面
- (void)enterWebViewPageWithView:(UIView *)view;

#pragma mark flutter

/// 内嵌页面元素信息
///
/// 目前用于接收 Flutter 页面元素信息
///
/// @param pageInfo 元素信息 json
- (void)saveVisualizedMessage:(NSDictionary *)pageInfo;

#pragma mark viewController
/// 进入页面
- (void)enterViewController:(UIViewController *)viewController;

#pragma mark payloadHash
/// 根据截图 hash 获取完整 payloadHash
- (NSString *)fetchPayloadHashWithImageHash:(NSString *)imageHash;

/// 追加 payloadHash
- (void)refreshPayloadHashWithData:(id)obj;

/// 更新最后一次 payloadHash
- (void)updateLastPayloadHash:(NSString *)payloadHash;

@end
