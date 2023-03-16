//
// HNRequestDeepLinkProcessor.m
// HinaDataSDK
//
// Created by hina on 2022/3/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNRequestDeepLinkProcessor.h"
#import "HNDeepLinkConstants.h"
#import "HinaDataSDK+Private.h"
#import "HNJSONUtil.h"
#import "HNConstants+Private.h"

static NSString *const kSchemeDeepLinkHost = @"hinadata";

@implementation HNRequestDeepLinkProcessor

+ (BOOL)isValidURL:(NSURL *)url customChannelKeys:(NSSet *)customChannelKeys {
   if ([self isCustomDeepLinkURL:url]) {
        return YES;
    }
    return [self isNormalDeepLinkURL:url];
}

/// URL 的 Path 符合特定规则。示例：https://{域名}/sd/{appId}/{key} 或 {scheme}://hinadata/sd/{key}
/// 数据接收地址环境对应的域名短链
+ (BOOL)isNormalDeepLinkURL:(NSURL *)url {
    NSArray *pathComponents = url.pathComponents;
    if (pathComponents.count < 2 || ![pathComponents[1] isEqualToString:@"sd"]) {
        return NO;
    }
    NSString *host = HinaDataSDK.sharedInstance.network.serverURL.host;
    if ([url.host caseInsensitiveCompare:kSchemeDeepLinkHost] == NSOrderedSame) {
        return YES;
    }
    if (!host) {
        return NO;
    }
    return [url.host caseInsensitiveCompare:host] == NSOrderedSame;
}

/// URL 的 Path 符合特定规则。示例：https://{ 自定义域名}/slink/{appId}/{key} 或 {scheme}://hinadata/slink/{key}
/// 自定义域名对应的域名短链
+ (BOOL)isCustomDeepLinkURL:(NSURL *)url {
    // 如果没有配置 SaaS 环境域名，则不处理
    NSString *channelURL = HinaDataSDK.sharedInstance.configOptions.customADChannelURL;
    if (channelURL.length == 0) {
        return NO;
    }
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:channelURL];
    NSArray *pathComponents = url.pathComponents;
    if (pathComponents.count < 2 || ![pathComponents[1] isEqualToString:@"slink"]) {
        return NO;
    }

    NSString *primaryDomain = [self primaryDomainForURL:url];
    NSString *channelPrimaryDomain = [self primaryDomainForURL:components.URL];

    if ([url.host caseInsensitiveCompare:kSchemeDeepLinkHost] == NSOrderedSame) {
        return YES;
    }
    if (!channelPrimaryDomain) {
        return NO;
    }
    return [primaryDomain caseInsensitiveCompare:channelPrimaryDomain] == NSOrderedSame;
}

+ (NSString *)primaryDomainForURL:(NSURL *)url {
    NSArray *hostArray = [url.host componentsSeparatedByString:@"."];
    if (hostArray.count < 2) {
        return nil;
    }
    NSMutableArray *primaryDomainArray = [hostArray mutableCopy];
    [primaryDomainArray removeObjectAtIndex:0];
    return [primaryDomainArray componentsJoinedByString:@"."];
}

- (BOOL)canWakeUp {
    return YES;
}

- (void)startWithProperties:(NSDictionary *)properties {
    // ServerMode 先触发 Launch 事件再请求接口，Launch 事件中只新增 H_deeplink_url 属性
    [self trackDeepLinkLaunch:properties];
    [self requestDeepLinkInfo];
}

- (NSURLRequest *)buildRequest {

    NSURLComponents *components;
    NSString *channelURL = HinaDataSDK.sharedInstance.configOptions.customADChannelURL;
    HNNetwork *network = HinaDataSDK.sharedInstance.network;
    NSString *key = self.URL.lastPathComponent;
    NSString *project = HinaDataSDK.sharedInstance.network.project;

    if ([self.class isCustomDeepLinkURL:self.URL]) {
        components = [[NSURLComponents alloc] initWithString:channelURL];
        components.path = [components.path stringByAppendingPathComponent:@"/slink/config/query"];
    } else if ([self.class isNormalDeepLinkURL:self.URL]) {
        components = network.baseURLComponents;
        components.path = [network.baseURLComponents.path stringByAppendingPathComponent:@"/sdk/deeplink/param"];
    }

    components.query = [NSString stringWithFormat:@"key=%@&project=%@&system_type=IOS", key, project];

    if (!components) {
        return nil;
    }

    NSURL *URL = [components URL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    request.timeoutInterval = 60;
    [request setHTTPMethod:@"GET"];
    return request;
}

- (void)requestDeepLinkInfo {
    NSURLRequest *request = [self buildRequest];
    if (!request) {
        return;
    }
    NSTimeInterval start = NSDate.date.timeIntervalSince1970;
    NSURLSessionDataTask *task = [HNHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *data, NSHTTPURLResponse *response, NSError *error) {
        NSTimeInterval interval = (NSDate.date.timeIntervalSince1970 - start);
        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        properties[kHNEventPropertyDuration] = [NSString stringWithFormat:@"%.3f", interval];

        NSDictionary *latestChannels;

        HNDeepLinkObject *obj = [[HNDeepLinkObject alloc] init];
        obj.appAwakePassedTime = interval * 1000;
        obj.success = NO;

        if (response.statusCode == 200 && data) {
            NSDictionary *result = [HNJSONUtil JSONObjectWithData:data];
            properties[kHNEventPropertyDeepLinkOptions] = result[kHNResponsePropertyParams];
            NSString *errorMsg = result[kHNResponsePropertyErrorMessage] ?: result[kHNResponsePropertyErrorMsg];
            properties[kHNEventPropertyDeepLinkFailReason] = errorMsg;
            properties[kHNEventPropertyADSLinkID] = result[kHNResponsePropertySLinkID];
            properties[kHNDynamicSlinkEventPropertyTemplateID] = result[kHNDynamicSlinkParamTemplateID];
            NSDictionary *customParams = result[kHNDynamicSlinkResponseKeyCustomParams];
            if ([customParams isKindOfClass:[NSDictionary class]] && customParams.allKeys.count > 0) {
                properties[kHNDynamicSlinkEventPropertyCustomParams] = [HNJSONUtil stringWithJSONObject:customParams];
            }
            properties[kHNDynamicSlinkEventPropertyType] = result[kHNDynamicSlinkParamType];

            // Result 事件中只需要添加 H_utm_content 等属性，不需要添加 H_latest_utm_content 等属性
            NSDictionary *channels = [self acquireChannels:result[kHNResponsePropertyChannelParams]];
            [properties addEntriesFromDictionary:channels];

            // 解析并并转换为 H_latest_utm_content 属性，并添加到后续事件所有事件中
            latestChannels = [self acquireLatestChannels:result[kHNResponsePropertyChannelParams]];

            obj.params = result[kHNResponsePropertyParams];
            NSInteger code = [result[kHNResponsePropertyCode] integerValue];
            obj.success = (code == 0 && errorMsg.length == 0);
            obj.customParams = result[kHNDynamicSlinkResponseKeyCustomParams];
        } else {
            NSString *codeMsg = [NSString stringWithFormat:@"http status code: %@",@(response.statusCode)];
            properties[kHNEventPropertyDeepLinkFailReason] = error.localizedDescription ?: codeMsg;
        }

        [self trackDeepLinkMatchedResult:properties];

        if ([self.delegate respondsToSelector:@selector(sendChannels:latestChannels:isDeferredDeepLink:)]) {
            // 当前方式不需要获取 channels 信息，只需要保存 latestChannels 信息
            dispatch_async(dispatch_get_main_queue(), ^{
                HNDeepLinkCompletion completion = [self.delegate sendChannels:nil latestChannels:latestChannels isDeferredDeepLink:NO];
                if (completion) {
                    completion(obj);
                }
            });
        }
    }];
    [task resume];
}

@end
