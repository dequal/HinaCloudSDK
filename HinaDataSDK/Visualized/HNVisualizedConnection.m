//
// HNVisualizedConnection.m,
// HinaDataSDK
//
// Created by hina on 2022/9/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "HNVisualizedConnection.h"
#import "HNVisualizedMessage.h"
#import "HNVisualizedSnapshotMessage.h"
#import "HNLog.h"
#import "HinaDataSDK+Private.h"
#import "HNVisualizedObjectSerializerManager.h"
#import "HNJSONUtil.h"
#import "HNConstants+Private.h"
#import "HNVisualizedManager.h"
#import "HNVisualizedLogger.h"
#import "HNFlutterPluginBridge.h"

@interface HNVisualizedConnection ()
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation HNVisualizedConnection {
    BOOL _connected;
    NSDictionary *_typeToMessageClassMap;
    NSOperationQueue *_commandQueue;
    id<HNVisualizedMessage> _designerMessage;
    NSString *_featureCode;
    NSString *_postUrl;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _typeToMessageClassMap = @{
            HNVisualizedSnapshotRequestMessageType : [HNVisualizedSnapshotRequestMessage class],
        };
        _connected = NO;
        _commandQueue = [[NSOperationQueue alloc] init];
        _commandQueue.maxConcurrentOperationCount = 1;
        _commandQueue.suspended = YES;

        [self setUpListeners];
    }

    return self;
}

- (void)setUpListeners {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];

    [notificationCenter addObserver:self selector:@selector(receiveVisualizedMessageFromH5:) name:kHNVisualizedMessageFromH5Notification object:nil];
}

#pragma mark notification Action
- (void)applicationDidBecomeActive {

    // 开启上传信息任务定时器
    [self startSendMessageTimer];
}

- (void)applicationDidEnterBackground {

    // 关闭上传信息任务定时器
    [self stopSendMessageTimer];
}

// App 内嵌 H5 的页面信息，包括页面元素、提示弹框、页面信息
- (void)receiveVisualizedMessageFromH5:(NSNotification *)notification {
    WKScriptMessage *message = notification.object;
    WKWebView *webView = message.webView;
    if (![webView isKindOfClass:WKWebView.class]) {
        HNLogError(@"Message webview is invalid from JS SDK");
        return;
    }
    
    NSMutableDictionary *messageDic = [HNJSONUtil JSONObjectWithString:message.body options:NSJSONReadingMutableContainers];
    if (![messageDic isKindOfClass:[NSDictionary class]]) {
        HNLogError(@"Message body is formatted failure from JS SDK");
        return;
    }
    
    [[HNVisualizedObjectSerializerManager sharedInstance] saveVisualizedWebPageInfoWithWebView:webView webPageInfo:messageDic];
}


/// 开始计时
- (void)startSendMessageTimer {
    _commandQueue.suspended = NO;
    if (!self.timer || ![self.timer isValid]) {
        return;
    }
    // 恢复计时器
    [self.timer setFireDate:[NSDate date]];

    // 通知外部，开始可视化全埋点连接
    [HNFlutterPluginBridge.sharedInstance changeVisualConnectionStatus:YES];
}

/// 暂停计时
- (void)stopSendMessageTimer {
    _commandQueue.suspended = YES;
    
    if (!self.timer || ![self.timer isValid]) {
        return;
    }

    // 暂停计时
    [self.timer setFireDate:[NSDate distantFuture]];

    // 通知外部，已断开可视化全埋点连接
    [HNFlutterPluginBridge.sharedInstance changeVisualConnectionStatus:NO];
}

#pragma mark action
- (void)close {
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }

    if (_commandQueue) {
        [_commandQueue cancelAllOperations];
        _commandQueue = nil;
    }

    // 清空缓存的配置数据
    [[HNVisualizedObjectSerializerManager sharedInstance] cleanVisualizedWebPageInfoCache];

    // 关闭埋点校验
    [HNVisualizedManager.defaultManager enableEventCheck:NO];

    // 关闭诊断信息收集
    [HNVisualizedManager.defaultManager.visualPropertiesTracker enableCollectDebugLog:NO];

    // 通知外部，已断开可视化全埋点连接
    dispatch_async(dispatch_get_main_queue(), ^{
        [HNFlutterPluginBridge.sharedInstance changeVisualConnectionStatus:NO];
    });
}

- (BOOL)isVisualizedConnecting {
    return self.timer && self.timer.isValid;
}

- (void)dealloc {
    [self close];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sendMessage:(id<HNVisualizedMessage>)message {
    if (_connected) {
        if (_featureCode == nil || _postUrl == nil) {
            return;
        }
        NSString *jsonString = [[NSString alloc] initWithData:[message JSONDataWithFeatureCode:_featureCode] encoding:NSUTF8StringEncoding];
        NSURL *URL = [NSURL URLWithString:_postUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
        NSURLSessionDataTask *task = [HNHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
            NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (response.statusCode == 200) {
                NSDictionary *dict = [HNJSONUtil JSONObjectWithString:urlResponseContent];
                int delay = [dict[@"delay"] intValue];
                if (delay < 0) {
                    [self close];
                }
                
                // 切到主线程，和 HNVisualizedManager 中调用一致
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self analysisDebugMessage:dict];
                });
            }
        }];

        [task resume];
    } else {
        HNLogWarn(@"No message will be sent because there is no connection: %@", [message debugDescription]);
    }
}

/// 解析调试信息
- (void)analysisDebugMessage:(NSDictionary *)message {
    // 关闭自定义属性也不再处理调试信息
    if (message.count == 0 || !HNVisualizedManager.defaultManager.configOptions.enableVisualizedProperties) {
        return;
    }

    // 解析可视化全埋点配置
    NSDictionary *configDic = message[@"visualized_sdk_config"];
    // 是否关闭自定义属性
    BOOL disableConfig = [message[@"visualized_config_disabled"] boolValue];
    if (disableConfig) {
        NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"switch control" message:@"the result returned by the polling interface, close custom properties through operations configuration"];
        HNLogDebug(@"%@", logMessage);

        [HNVisualizedManager.defaultManager.configSources setupConfigWithDictionary:nil disableConfig:YES];
    } else if (configDic.count > 0) {
        NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"get configuration" message:@"polling interface update visualized configuration, %@", configDic];
        HNLogInfo(@"%@", logMessage);

        [HNVisualizedManager.defaultManager.configSources setupConfigWithDictionary:configDic disableConfig:NO];
    }

    // 前端页面进入 &debug=1 调试模式
    BOOL isDebug = [message[@"visualized_debug_mode_enabled"] boolValue];
    [HNVisualizedManager.defaultManager.visualPropertiesTracker enableCollectDebugLog:isDebug];
}


- (id <HNVisualizedMessage>)designerMessageForMessage:(NSString *)message {
    if (![message isKindOfClass:[NSString class]]) {
        HNLogError(@"message type error:%@",message);
        return nil;
    }

    id jsonObject = [HNJSONUtil JSONObjectWithString:message];
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        HNLogError(@"Badly formed socket message expected JSON dictionary: %@", message);
        return nil;
    }

    NSDictionary *messageDictionary = (NSDictionary *)jsonObject;
    //snapshot_request
    NSString *type = messageDictionary[@"type"];
    NSDictionary *payload = messageDictionary[@"payload"];

    id <HNVisualizedMessage> designerMessage = [_typeToMessageClassMap[type] messageWithType:type payload:payload];
    return designerMessage;
}

#pragma mark -  Methods

- (void)startVisualizedTimer:(NSString *)message featureCode:(NSString *)featureCode postURL:(NSString *)postURL {
    _featureCode = featureCode;
    _postUrl = (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)postURL, CFSTR(""),  CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    _designerMessage = [self designerMessageForMessage:message];

    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(handleMessage)
                                                userInfo:nil
                                                 repeats:YES];

    // 发送通知，通知 flutter 已进入可视化全埋点扫码模式
    [HNFlutterPluginBridge.sharedInstance changeVisualConnectionStatus:YES];
}

- (void)handleMessage {
    if (_designerMessage) {
        NSOperation *commandOperation = [_designerMessage responseCommandWithConnection:self];
        if (commandOperation) {
            [_commandQueue addOperation:commandOperation];
        }
    }
}

- (void)startConnectionWithFeatureCode:(NSString *)featureCode url:(NSString *)urlStr {
    NSBundle *hinaBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[HinaDataSDK class]] pathForResource:@"HinaDataSDK" ofType:@"bundle"]];

    NSString *jsonPath = [hinaBundle pathForResource:@"sa_visualized_path.json" ofType:nil];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    _commandQueue.suspended = NO;
    self->_connected = YES;
    [self startVisualizedTimer:jsonString featureCode:featureCode postURL:urlStr];
}

@end

