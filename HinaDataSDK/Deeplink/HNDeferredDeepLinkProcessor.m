//
// HNDeferredDeepLinkProcessor.m
// HinaDataSDK
//
// Created by hina on 2022/3/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDeferredDeepLinkProcessor.h"
#import "HNDeepLinkConstants.h"
#import "HinaDataSDK+Private.h"
#import "HNJSONUtil.h"
#import "HNNetwork.h"
#import "HNUserAgent.h"
#import "HNNetworkInfoPropertyPlugin.h"
#import "HNConstants+Private.h"

@implementation HNDeferredDeepLinkProcessor

- (void)startWithProperties:(NSDictionary *)properties {
    NSString *userAgent = properties[kHNRequestPropertyUserAgent];
    if (userAgent.length > 0) {
        NSMutableDictionary *newProperties = [NSMutableDictionary dictionaryWithDictionary:properties];
        [newProperties removeObjectForKey:kHNRequestPropertyUserAgent];
        NSURLRequest *request = [self buildRequest:userAgent properties:newProperties];
        [self requestForDeferredDeepLink:request];
    } else {
        __block typeof(self) weakSelf = self;
        [HNUserAgent loadUserAgentWithCompletion:^(NSString *userAgent) {
            NSURLRequest *request = [weakSelf buildRequest:userAgent properties:properties];
            [weakSelf requestForDeferredDeepLink:request];
        }];
    }
}

- (void)requestForDeferredDeepLink:(NSURLRequest *)request {
    if (!request) {
        return;
    }
    NSTimeInterval start = NSDate.date.timeIntervalSince1970;
    NSURLSessionDataTask *task = [HNHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData *_Nullable data, NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        NSTimeInterval interval = (NSDate.date.timeIntervalSince1970 - start);

        NSMutableDictionary *properties = [NSMutableDictionary dictionary];
        properties[kHNEventPropertyDuration] = [NSString stringWithFormat:@"%.3f", interval];
        properties[kHNEventPropertyADMatchType] = @"deferred deeplink";

        NSData *deviceInfoData = [[self appInstallSource] dataUsingEncoding:NSUTF8StringEncoding];
        NSString *base64 = [deviceInfoData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
        properties[kHNEventPropertyADDeviceInfo] = base64;

        HNDeepLinkObject *obj = [[HNDeepLinkObject alloc] init];
        obj.appAwakePassedTime = interval * 1000;
        obj.success = NO;

        NSDictionary *latestChannels;
        NSString *slinkID;

        if (response.statusCode == 200) {
            NSDictionary *result = [HNJSONUtil JSONObjectWithData:data];
            properties[kHNEventPropertyDeepLinkOptions] = result[kHNResponsePropertyParameter];
            properties[kHNEventPropertyADChannel] = result[kHNResponsePropertyADChannel];
            properties[kHNEventPropertyDeepLinkFailReason] = result ? result[kHNResponsePropertyMessage] : @"response is null";
            properties[kHNEventPropertyADSLinkID] = result[kHNResponsePropertySLinkID];
            properties[kHNDynamicSlinkEventPropertyTemplateID] = result[kHNDynamicSlinkParamTemplateID];
            properties[kHNDynamicSlinkEventPropertyType] = result[kHNDynamicSlinkParamType];
            NSDictionary *customParams = result[kHNDynamicSlinkResponseKeyCustomParams];
            if ([customParams isKindOfClass:[NSDictionary class]] && customParams.allKeys.count > 0) {
                properties[kHNDynamicSlinkEventPropertyCustomParams] = [HNJSONUtil stringWithJSONObject:customParams];
            }
            obj.params = result[kHNResponsePropertyParameter];
            obj.adChannels = result[kHNResponsePropertyADChannel];
            obj.success = (result[kHNResponsePropertyCode] && [result[kHNResponsePropertyCode] integerValue] == 0);
            obj.customParams = result[kHNDynamicSlinkResponseKeyCustomParams];

            // Result 事件中添加 H_utm_* 属性
            [properties addEntriesFromDictionary:[self acquireChannels:result[kHNResponsePropertyChannelParams]]];

            // 解析并并转换为 H_latest_utm_content 属性，并添加到后续事件所有事件中
            latestChannels = [self acquireLatestChannels:result[kHNResponsePropertyChannelParams]];
            slinkID = result[kHNResponsePropertySLinkID];
        } else {
            NSString *codeMsg = [NSString stringWithFormat:@"http status code: %@",@(response.statusCode)];
            properties[kHNEventPropertyDeepLinkFailReason] = error.localizedDescription ?: codeMsg;
        }

        // 确保调用客户设置的 completion 是在主线程中
        dispatch_async(dispatch_get_main_queue(), ^{
            HNDeepLinkCompletion completion;
            if ([self.delegate respondsToSelector:@selector(sendChannels:latestChannels:isDeferredDeepLink:)]) {
                // 当前方式不需要获取 channels 信息，只需要保存 latestChannels 信息
                completion = [self.delegate sendChannels:nil latestChannels:latestChannels isDeferredDeepLink:YES];
            }
            if (obj.success && !completion) {
                properties[kHNEventPropertyDeepLinkFailReason] = HNLocalizedString(@"HNDeepLinkCallback");
            }
            [self trackDeepLinkMatchedResult:properties];

            if (!completion) {
                return;
            }

            BOOL jumpSuccess = completion(obj);
            // 只有当请求成功，并且客户跳转页面成功后，触发 H_AdAppDeferredDeepLinkJump 事件
            if (!obj.success || !jumpSuccess) {
                return;
            }
            HNPresetEventObject *object = [[HNPresetEventObject alloc] initWithEventId:kHNDeferredDeepLinkJumpEvent];
            NSMutableDictionary *jumpProps = [NSMutableDictionary dictionary];
            jumpProps[kHNEventPropertyDeepLinkOptions] = obj.params;
            jumpProps[kHNEventPropertyADSLinkID] = slinkID;
            jumpProps[kHNDynamicSlinkEventPropertyTemplateID] = properties[kHNDynamicSlinkEventPropertyTemplateID];
            jumpProps[kHNDynamicSlinkEventPropertyType] = properties[kHNDynamicSlinkEventPropertyType];
            jumpProps[kHNDynamicSlinkEventPropertyCustomParams] = properties[kHNDynamicSlinkEventPropertyCustomParams];

            [HinaDataSDK.sharedInstance trackEventObject:object properties:jumpProps];

        });
    }];
    [task resume];
}

- (NSURLRequest *)buildRequest:(NSString *)userAgent properties:(NSDictionary *)properties {
    NSString *channelURL = HinaDataSDK.sharedInstance.configOptions.customADChannelURL;
    NSURLComponents *components;
    if (channelURL.length > 0) {
        components = [[NSURLComponents alloc] initWithString:channelURL];
    } else {
        components = HinaDataSDK.sharedInstance.network.baseURLComponents;
    }

    if (!components) {
        return nil;
    }

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSData *data = [[self appInstallSource] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64 = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    params[kHNRequestPropertyIDs] = base64;
    params[kHNRequestPropertyUA] = userAgent;
    params[kHNRequestPropertyOS] = @"iOS";
    params[kHNRequestPropertyOSVersion] = UIDevice.currentDevice.systemVersion;
    params[kHNRequestPropertyModel] = UIDevice.currentDevice.model;
    HNNetworkInfoPropertyPlugin *plugin = [[HNNetworkInfoPropertyPlugin alloc] init];
    params[kHNRequestPropertyNetwork] = [plugin networkTypeString];
    NSInteger timestamp = [@([[NSDate date] timeIntervalSince1970] * 1000) integerValue];
    params[kHNRequestPropertyTimestamp] = @(timestamp);
    params[kHNRequestPropertyAppID] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    params[kHNRequestPropertyAppVersion] = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    params[kHNRequestPropertyAppParameter] = [HNJSONUtil stringWithJSONObject:properties];
    params[kHNRequestPropertyProject] = HinaDataSDK.sharedInstance.network.project;
    components.path = [components.path stringByAppendingPathComponent:@"/slink/ddeeplink"];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[components URL]];
    request.timeoutInterval = 60;
    request.HTTPBody = [HNJSONUtil dataWithJSONObject:params];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    return request;
}

@end
