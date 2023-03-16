//
// HNVisualizedAbstractMessage.m
// HinaDataSDK
//
// Created by hina on 2022/9/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "HNGzipUtility.h"
#import "HNVisualizedAbstractMessage.h"
#import "HinaDataSDK.h"
#import "HNLog.h"
#import "UIViewController+HNAutoTrack.h"
#import "HNVisualizedObjectSerializerManager.h"
#import "HNConstants+Private.h"
#import "HNVisualizedUtils.h"
#import "HNJSONUtil.h"
#import "HNVisualizedManager.h"
#import "HNUIProperties.h"

@interface HNVisualizedAbstractMessage ()

@property (nonatomic, copy, readwrite) NSString *type;

@end

@implementation HNVisualizedAbstractMessage {
    NSMutableDictionary *_payload;
}

+ (instancetype)messageWithType:(NSString *)type payload:(NSDictionary *)payload {
    return [[self alloc] initWithType:type payload:payload];
}

- (instancetype)initWithType:(NSString *)type {
    return [self initWithType:type payload:nil];
}

- (instancetype)initWithType:(NSString *)type payload:(NSDictionary *)payload {
    self = [super init];
    if (self) {
        _type = type;
        if (payload) {
             _payload = [payload mutableCopy];
        } else {
            _payload = [NSMutableDictionary dictionary];
        }
    }

    return self;
}

- (void)setPayloadObject:(id)object forKey:(NSString *)key {
    _payload[key] = object;
}

- (id)payloadObjectForKey:(NSString *)key {
    id object = _payload[key];
    return object;
}

- (void)removePayloadObjectForKey:(NSString *)key {
    if (!key) {
        return;
    }
    [_payload removeObjectForKey:key];
}

- (NSDictionary *)payload {
    return [_payload copy];
}

- (NSData *)JSONDataWithFeatureCode:(NSString *)featureCode {
    NSMutableDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    jsonObject[@"type"] = _type;
    jsonObject[@"os"] = @"iOS"; // 操作系统类型
    jsonObject[@"lib"] = @"iOS"; // SDK 类型
    
    HNVisualizedObjectSerializerManager *serializerManager = [HNVisualizedObjectSerializerManager sharedInstance];
    NSString *screenName = nil;
    NSString *pageName = nil;
    NSString *title = nil;
    
    @try {
        // 获取当前页面
        UIViewController *currentViewController = serializerManager.lastViewScreenController;
        if (!currentViewController) {
            currentViewController = [HNUIProperties currentViewController];
        }
        
        // 解析页面信息
        NSDictionary *autoTrackScreenProperties = [HNUIProperties propertiesWithViewController:currentViewController];
        screenName = autoTrackScreenProperties[kHNEventPropertyScreenName];
        pageName = autoTrackScreenProperties[kHNEventPropertyScreenName];
        title = autoTrackScreenProperties[kHNEventPropertyTitle];
        
        // 获取 RN 页面信息
        NSDictionary <NSString *, NSString *> *RNScreenInfo = [HNVisualizedUtils currentRNScreenVisualizeProperties];
        if (RNScreenInfo[kHNEventPropertyScreenName]) {
            pageName = RNScreenInfo[kHNEventPropertyScreenName];
            screenName = RNScreenInfo[kHNEventPropertyScreenName];
            title = RNScreenInfo[kHNEventPropertyTitle];
        }
    } @catch (NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
    
    jsonObject[@"page_name"] = pageName;
    jsonObject[@"screen_name"] = screenName;
    jsonObject[@"title"] = title;
    jsonObject[@"app_version"] = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    jsonObject[@"feature_code"] = featureCode;
    
    // 增加 appId
    jsonObject[@"app_id"] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    
    // 上传全埋点配置开启状态
    NSMutableArray<NSString *>* autotrackOptions = [NSMutableArray array];
    HinaDataAutoTrackEventType eventType = HinaDataSDK.sharedInstance.configOptions.autoTrackEventType;
    if (eventType &  HinaDataEventTypeAppClick) {
        [autotrackOptions addObject:kHNEventNameAppClick];
    }
    if (eventType &  HinaDataEventTypeAppViewScreen) {
        [autotrackOptions addObject:kHNEventNameAppViewScreen];
    }
    jsonObject[@"app_autotrack"] = autotrackOptions;
    
    // 自定义属性开关状态
    jsonObject[@"app_enablevisualizedproperties"] = @(HNVisualizedManager.defaultManager.configOptions.enableVisualizedProperties);
    
    HNVisualizedPageInfo *webPageInfo = [serializerManager queryPageInfoWithType:HNVisualizedPageTypeWeb];
    HNVisualizedPageInfo *flutterPageInfo = [serializerManager queryPageInfoWithType:HNVisualizedPageTypeFlutter];
    
    // 当前为 Flutter 页面
    if (flutterPageInfo.pageType == HNVisualizedPageTypeFlutter) {
        jsonObject[@"page_name"] = flutterPageInfo.screenName;
        jsonObject[@"screen_name"] = flutterPageInfo.screenName;
        jsonObject[@"title"] = flutterPageInfo.title;
        jsonObject[@"flutter_lib_version"] = flutterPageInfo.platformSDKLibVersion;
    }

    // 添加前端弹框信息
    if (webPageInfo.alertInfos.count > 0) {
        jsonObject[@"app_alert_infos"] = [webPageInfo.alertInfos.allValues copy];
    }
    
    // H5 页面信息
    if (webPageInfo.pageType == HNVisualizedPageTypeWeb) {
        jsonObject[@"is_webview"] = @(YES);

        jsonObject[@"h5_url"] = webPageInfo.url;
        jsonObject[@"h5_title"] = webPageInfo.title;
        jsonObject[@"web_lib_version"] = webPageInfo.platformSDKLibVersion;
    }
    
    // SDK 版本号
    jsonObject[@"lib_version"] = HinaDataSDK.sharedInstance.libVersion;
    // 可视化全埋点配置版本号
    jsonObject[@"config_version"] = [HNVisualizedManager defaultManager].configSources.configVersion;
    
    if (_payload.count == 0) {
        return [HNJSONUtil dataWithJSONObject:jsonObject];
    }
    // 如果使用 GZip 压缩
    // 1. 序列化 Payload
    NSData *jsonData = [HNJSONUtil dataWithJSONObject:_payload];
    
    // 2. 使用 GZip 进行压缩
    NSData *zippedData = [HNGzipUtility gzipData:jsonData];
    
    // 3. Base64 Encode
    NSString *b64String = [zippedData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    
    jsonObject[@"gzip_payload"] = b64String;
    
    return [HNJSONUtil dataWithJSONObject:jsonObject];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@:%p type='%@'>", NSStringFromClass([self class]), (__bridge void *)self, self.type];
}

@end
