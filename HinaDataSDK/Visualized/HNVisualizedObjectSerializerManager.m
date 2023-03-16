//
// HNVisualizedObjectSerializerManager.m
// HinaDataSDK
//
// Created by hina on 2022/4/23.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNVisualizedObjectSerializerManager.h"
#import "HNJSONUtil.h"
#import "HNLog.h"
#import "HNVisualizedManager.h"
#import "HNCommonUtility.h"
#import "HNUIProperties.h"
#import "HNConstants+Private.h"

@implementation HNVisualizedPageInfo

- (instancetype)initWithPageType:(HNVisualizedPageType)pageType {
    self = [super init];
    if (self) {
        _pageType = pageType;
        _alertInfos = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)registWebAlertInfos:(NSArray <NSDictionary *> *)infos {
    if (infos.count == 0) {
        return;
    }

    BOOL isRegistedAlertInfos = NO;
    // 只添加 message 不重复的弹框信息
    for (NSDictionary *alertInfo in infos) {
        NSString *message = alertInfo[@"message"];
        if (message) {
            // 和已有弹框重复
            if ([self.alertInfos[message]  isEqualToDictionary:alertInfo]) {
                break;
            }
            self.alertInfos[message] = alertInfo;
            isRegistedAlertInfos = YES;
        }
    }

    // 注册弹框成功，更新 hash
    if (isRegistedAlertInfos) {
        [[HNVisualizedObjectSerializerManager sharedInstance] refreshPayloadHashWithData:infos];
    }
}

@end


@interface HNVisualizedObjectSerializerManager()

/// 非法页面信息，可能是 UIWebView 页面
@property (nonatomic, strong) HNVisualizedPageInfo *invalidPageInfo;

/// payload 新增内容对应 hash，如果存在，则添加到 image_hash 后缀
@property (nonatomic, copy) NSString *jointPayloadHash;

/// 上次数据包标识 hash
@property (nonatomic, copy, readwrite) NSString *lastPayloadHash;

/// 记录当前栈中的 controller，不会持有
@property (nonatomic, strong) NSPointerArray *controllersStack;

/// H5 或 Flutter 页面信息缓存
/*
 key:H5 页面 url 或当前页面地址
 value:HNVisualizedWebPageInfo 对象
 */
@property (nonatomic, strong) NSMutableDictionary <NSString *,HNVisualizedPageInfo *>*webPageInfoCache;

/// 当前 webView 页面
@property (nonatomic, weak) WKWebView *webView;
@end

@implementation HNVisualizedObjectSerializerManager

+ (instancetype)sharedInstance {
    static HNVisualizedObjectSerializerManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HNVisualizedObjectSerializerManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initializeObjectSerializer];
    }
    return self;
}

- (void)initializeObjectSerializer {

    /* NSPointerArray 使用 weakObjectsPointerArray 初始化
     对于集合中的对象不会强引用，如果对象被释放，则会被置为 NULL，调用 compact 即可移除所有 NULL 对象
     */
    _controllersStack = [NSPointerArray weakObjectsPointerArray];
    _webPageInfoCache = [NSMutableDictionary dictionary];
}

/// 重置解析配置
- (void)resetObjectSerializer {
    self.invalidPageInfo = nil;
    self.webView = nil;
}

- (void)cleanVisualizedWebPageInfoCache {
    [self.webPageInfoCache removeAllObjects];
    self.invalidPageInfo = nil;

    self.jointPayloadHash = nil;
    self.lastPayloadHash = nil;
    self.webView = nil;
}

- (HNVisualizedPageInfo *)queryPageInfoWithType:(HNVisualizedPageType)pageType {
    if (self.webView && pageType == HNVisualizedPageTypeWeb) {
        return [self readWebPageInfoWithWebView:self.webView];
    }
    if (pageType == HNVisualizedPageTypeFlutter) {
        HNVisualizedPageInfo *pageInfo = [self readFlutterPageInfo];
        if (pageInfo) {
            return pageInfo;
        }
    }
    if (pageType == HNVisualizedPageTypeNative) {
        HNVisualizedPageInfo *pageInfo = [self readNativePageInfo];
        if (pageInfo) {
            return pageInfo;
        }
    }
    return self.invalidPageInfo;
}

#pragma mark - WebInfo
/// 读取当前 webView 页面相关信息
- (HNVisualizedPageInfo *)readWebPageInfoWithWebView:(WKWebView *)webView {
    if (!webView) {
        return nil;
    }
    NSString *url = webView.URL.absoluteString;
    HNVisualizedPageInfo *webPageInfo = [self.webPageInfoCache objectForKey:url];
    return webPageInfo;
}

/// 缓存可视化全埋点相关 web 信息
- (void)saveVisualizedWebPageInfoWithWebView:(WKWebView *)webview webPageInfo:(NSMutableDictionary *)pageInfo {

    NSString *callType = pageInfo[@"callType"];
    if ([callType isEqualToString:@"visualized_track"]) { // 页面元素信息

        [self saveWebElementInfoWithData:pageInfo webView:webview];
    } else if ([callType isEqualToString:@"app_alert"]) { // 弹框提示信息

        [self saveWebAlertInfoWithData:pageInfo webView:webview];

    } else if ([callType isEqualToString:@"page_info"]) { // h5 页面信息
        [self saveWebPageInfoWithData:pageInfo webView:webview];
    }

    // 刷新数据
    [self refreshPayloadHashWithData:pageInfo];
}

/// 保存 H5 元素信息，并设置状态
- (void)saveWebElementInfoWithData:(NSMutableDictionary *)pageInfo webView:(WKWebView *)webview {
    // H5 页面可点击元素数据
    NSArray *pageDatas = pageInfo[@"data"];
    // 老版本 Web JS SDK 兼容，老版不包含 enable_click 字段，可点击元素需要设置标识
    for (NSMutableDictionary *elementInfoDic in pageDatas) {
        elementInfoDic[@"enable_click"] = @YES;
    }

    // H5 页面可见非点击元素
    NSArray *extraElements = pageInfo[@"extra_elements"];

    if (pageDatas.count == 0 && extraElements.count == 0) {
        return;
    }
    NSMutableArray *webElementSources = [NSMutableArray array];
    if (pageDatas.count > 0) {
        [webElementSources addObjectsFromArray:pageDatas];
    }
    if (extraElements.count > 0) {
        [webElementSources addObjectsFromArray:extraElements];
    }

    NSDictionary *elementInfo = [webElementSources firstObject];
    NSString *url = elementInfo[@"H_url"];
    if (!url) {
        return;
    }

    HNVisualizedPageInfo *webPageInfo = nil;
    // 是否包含当前 url 的页面信息
    if ([self.webPageInfoCache objectForKey:url]) {
        webPageInfo = self.webPageInfoCache[url];

        // 更新 H5 元素信息，则可视化全埋点可用，此时清空弹框信息
        [webPageInfo.alertInfos removeAllObjects];
    } else {
        webPageInfo = [[HNVisualizedPageInfo alloc] initWithPageType:HNVisualizedPageTypeWeb];
        self.webPageInfoCache[url] = webPageInfo;
    }
    webPageInfo.elementSources = [webElementSources copy];
}

/// 保存 web 当前页面信息
- (void)saveWebViewVisualizedPageInfo:(HNVisualizedPageInfo *)webPageInfo withWebView:(WKWebView *)webview {
    NSString *url = webview.URL.absoluteString;
    if (!webPageInfo || !url) {
        return;
    }
    self.webPageInfoCache[url] = webPageInfo;
}

/// 保存 H5 页面弹框信息
- (void)saveWebAlertInfoWithData:(NSDictionary *)pageInfo webView:(WKWebView *)webview {
    /*
     [{
     "title": "弹框标题",
     "message": "App SDK 与 Web SDK 没有进行打通，请联系贵方技术人员修正 Web SDK 的配置，详细信息请查看文档。",
     "link_text": "配置文档"
     "link_url": "https://manual.hinadata.cn/sa/latest/app-h5-1573913.html"
     }]
     */
    NSArray <NSDictionary *> *alertDatas = pageInfo[@"data"];
    NSString *url = webview.URL.absoluteString;
    if (![alertDatas isKindOfClass:NSArray.class] || !url) {
        return;
    }

    HNVisualizedPageInfo *webPageInfo = nil;
    // 是否包含当前 url 的页面信息
    if ([self.webPageInfoCache objectForKey:url]) {
        webPageInfo = self.webPageInfoCache[url];

        // 如果 js 发送弹框信息，即 js 环境变化，可视化全埋点不可用，则清空页面信息
        webPageInfo.elementSources = nil;
        webPageInfo.url = nil;
        webPageInfo.title = nil;
    } else {
        webPageInfo = [[HNVisualizedPageInfo alloc] initWithPageType:HNVisualizedPageTypeWeb];
        self.webPageInfoCache[url] = webPageInfo;
    }

    // 区分点击分析和可视化全埋点，针对 JS 发送的弹框信息，截取标题替换处理
    if ([HNVisualizedManager defaultManager].visualizedType == HinaDataVisualizedTypeHeatMap) {
        NSMutableArray <NSDictionary *>* alertNewDatas = [NSMutableArray array];
        for (NSDictionary *alertDic in alertDatas) {
            NSMutableDictionary <NSString *, NSString *>* alertNewDic = [NSMutableDictionary dictionaryWithDictionary:alertDic];
            alertNewDic[@"title"] = [alertDic[@"title"] stringByReplacingOccurrencesOfString:HNLocalizedString(@"HNVisualizedAutoTrack") withString:HNLocalizedString(@"HNAppClickHNnalytics")];
            [alertNewDatas addObject:alertNewDic];
        };
        alertDatas = [alertNewDatas copy];
    }
    [webPageInfo registWebAlertInfos:alertDatas];
}

/// 保存 H5 页面信息
- (void)saveWebPageInfoWithData:(NSDictionary *)pageInfo webView:(WKWebView *)webview {
    NSDictionary *webInfo = pageInfo[@"data"];
    NSString *url = webInfo[@"H_url"];
    NSString *libVersion = webInfo[@"lib_version"];

    if (![webInfo isKindOfClass:NSDictionary.class] || !url) {
        return;
    }
    HNVisualizedPageInfo *webPageInfo = nil;
    // 是否包含当前 url 的页面信息
    if ([self.webPageInfoCache objectForKey:url]) {
        webPageInfo = self.webPageInfoCache[url];
        // 更新 H5 页面信息，则可视化全埋点可用，此时清空弹框信息
        [webPageInfo.alertInfos removeAllObjects];
    } else {
        webPageInfo = [[HNVisualizedPageInfo alloc] initWithPageType:HNVisualizedPageTypeWeb];
        self.webPageInfoCache[url] = webPageInfo;
    }

    webPageInfo.url = url;
    webPageInfo.title = webInfo[@"H_title"];
    webPageInfo.platformSDKLibVersion = libVersion;
}

- (void)enterWebViewPageWithView:(UIView *)view {
    HNVisualizedPageInfo *webInfo = nil;
    if ([view isKindOfClass:NSClassFromString(@"FlutterView")]) {
        webInfo = [self readFlutterPageInfo];
        if (!webInfo) { // 标记进入 Flutter，但是无页面信息
            webInfo = [[HNVisualizedPageInfo alloc] initWithPageType:HNVisualizedPageTypeFlutter];
            [self saveFlutterPageInfo:webInfo];
        }
    } else if ([view isKindOfClass:WKWebView.class]) {
        WKWebView *webView = (WKWebView *)view;
        webInfo = [self readWebPageInfoWithWebView:webView];

        self.webView = webView;
        if (!webInfo) { // 标记进入 H5，但是无页面信息
            webInfo = [[HNVisualizedPageInfo alloc] initWithPageType:HNVisualizedPageTypeWeb];
            [self saveWebViewVisualizedPageInfo:webInfo withWebView:webView];
        }
    } else { // 可能是 UIWebView，暂不支持可视化全埋点
        webInfo = [[HNVisualizedPageInfo alloc] initWithPageType:HNVisualizedPageTypeWeb];
        NSMutableDictionary *alertInfo = [NSMutableDictionary dictionary];
        alertInfo[@"title"] =  HNLocalizedString(@"HNVisualizedPageErrorTitle");
        alertInfo[@"message"] = HNLocalizedString(@"HNVisualizedWebPageErrorMessage");
        alertInfo[@"link_text"] = HNLocalizedString(@"HNVisualizedConfigurationDocument");
        alertInfo[@"link_url"] = @"https://manual.hinadata.cn/sa/latest/enable_visualized_autotrack-7548675.html";
        if ([HNVisualizedManager defaultManager].visualizedType == HinaDataVisualizedTypeHeatMap) {
            alertInfo[@"title"] = HNLocalizedString(@"HNAppClickHNnalyticsPageErrorTitle");
            alertInfo[@"message"] = HNLocalizedString(@"HNAppClickHNnalyticsPageWebErrorMessage");
            alertInfo[@"link_url"] = @"https://manual.hinadata.cn/sa/latest/app-16286049.html";
        }
        [webInfo registWebAlertInfos:@[alertInfo]];
        self.invalidPageInfo = webInfo;
    }
}

#pragma mark flutter
/// 保存 flutter 页面元素信息
- (void)saveVisualizedMessage:(NSDictionary *)pageInfo {
    NSString *callType = pageInfo[@"callType"];

    HNVisualizedPageInfo *flutterPageInfo = nil;
    UIViewController *currentVC = [HNUIProperties currentViewController];
    // flutter 页面判断
    Class flutterClass = NSClassFromString(@"FlutterViewController");
    if (!flutterClass || ![currentVC isKindOfClass:flutterClass]) {
        return;
    }
    NSString *address = [NSString stringWithFormat:@"%p", currentVC];

    if (self.webPageInfoCache[address]) { // 获取缓存信息
        flutterPageInfo = self.webPageInfoCache[address];
    } else {
        flutterPageInfo =  [[HNVisualizedPageInfo alloc] initWithPageType:HNVisualizedPageTypeFlutter];
    }

    // Flutter 页面信息
    if ([callType isEqualToString:@"page_info"]) {
        NSDictionary *pageInfoData = pageInfo[@"data"];
        if (!pageInfoData[@"screen_name"]) {
            HNLogWarn(@"flutter pageInfo error: %@", pageInfo);
            return;
        }
        flutterPageInfo.title = pageInfoData[@"title"];
        flutterPageInfo.screenName = pageInfoData[@"screen_name"];
        flutterPageInfo.platformSDKLibVersion = pageInfoData[@"lib_version"];
    } else if ([callType isEqualToString:@"visualized_track"]) { // Flutter 页面元素信息
        NSArray *elementSources = pageInfo[@"data"];
        flutterPageInfo.elementSources = elementSources;
    }

    [flutterPageInfo.alertInfos removeAllObjects];
    self.webPageInfoCache[address] = flutterPageInfo;

    [self refreshPayloadHashWithData:pageInfo];
}

/// 读取 Flutter 页面信息
- (HNVisualizedPageInfo *)readFlutterPageInfo {
    UIViewController *currentVC = [HNUIProperties currentViewController];
    Class flutterClass = NSClassFromString(@"FlutterViewController");
    if (!flutterClass || ![currentVC isKindOfClass:flutterClass]) {
     nil;
    }
    NSString *address = [NSString stringWithFormat:@"%p", currentVC];
    return self.webPageInfoCache[address];
}

/// 读取 Native 页面信息
- (HNVisualizedPageInfo *)readNativePageInfo {
    UIViewController *currentVC = self.lastViewScreenController;
    if (!currentVC) {
        currentVC = [HNUIProperties currentViewController];
    }
    if (!currentVC) {
        return nil;
    }
    NSString *address = [NSString stringWithFormat:@"%p", currentVC];
    return self.webPageInfoCache[address];
}

/// 保存 Flutter 当前页面信息
- (void)saveFlutterPageInfo:(HNVisualizedPageInfo *)flutterPageInfo {
    UIViewController *currentVC = [HNUIProperties currentViewController];
    Class flutterClass = NSClassFromString(@"FlutterViewController");
    if (!flutterClass || ![currentVC isKindOfClass:flutterClass]) {
     nil;
    }
    NSString *address = [NSString stringWithFormat:@"%p", currentVC];
    self.webPageInfoCache[address] = flutterPageInfo;
}

#pragma mark enter viewScreenController
/// 进入页面
- (void)enterViewController:(UIViewController *)viewController {
    [self removeAllNullInControllersStack];
    [self.controllersStack addPointer:(__bridge void * _Nullable)(viewController)];
}

- (UIViewController *)lastViewScreenController {
    // allObjects 会自动过滤 NULL
    if (self.controllersStack.allObjects.count == 0) {
        return nil;
    }
    UIViewController *lastVC = [self.controllersStack.allObjects lastObject];

    // 如果 viewController 不在屏幕显示就移除
    while (lastVC && !lastVC.view.window) {
        // 如果 count 不等，即 controllersStack 存在 NULL
        if (self.controllersStack.count > self.controllersStack.allObjects.count) {
            [self removeAllNullInControllersStack];
        }

        // 移除最后一个不显示的 viewController
        [self.controllersStack removePointerAtIndex:self.controllersStack.count - 1];
        if (self.controllersStack.allObjects.count == 0) {
            return nil;
        }
        lastVC = [self.controllersStack.allObjects lastObject];
    }
    return lastVC;
}

/// 移除 controllersStack 中所有 NULL
- (void)removeAllNullInControllersStack {
    // 每次 compact 之前需要添加 NULL，规避系统 Bug（compact 函数有个已经报备的 bug，每次 compact 之前需要添加一个 NULL，否则会 compact 失败）
    [self.controllersStack addPointer:NULL];
    [self.controllersStack compact];
}

#pragma mark payloadHash
/// 根据截图 hash 获取完整 PayloadHash
- (NSString *)fetchPayloadHashWithImageHash:(NSString *)imageHash {
    if (self.jointPayloadHash.length == 0) {
        return imageHash;
    }
    if (imageHash.length == 0) {
        return self.jointPayloadHash;
    }
    return [imageHash stringByAppendingString:self.jointPayloadHash];
}

- (void)updateLastPayloadHash:(NSString *)payloadHash {
    self.lastPayloadHash = payloadHash;
}

/// 刷新截图 imageHash 信息
- (void)refreshPayloadHashWithData:(id)obj {
    /*
     App 内嵌 H5 的可视化全埋点，可能页面加载完成，但是未及时接收到 Html 页面信息。
     等接收到 JS SDK 发送的页面信息，由于页面截图不变，前端页面未重新加载解析 viewTree 信息，导致无法圈选。
     所以，接收到 JS 的页面信息，在原有 imageHash 基础上拼接 html 页面数据 hash 值，使得前端重新加载页面信息
     */
    if (!obj) {
        return;
    }

    NSData *jsonData = [HNJSONUtil dataWithJSONObject:obj];
    if (jsonData) {
        // 计算 hash
        self.jointPayloadHash = [HNCommonUtility hashStringWithData:jsonData];
    }
}

@end

