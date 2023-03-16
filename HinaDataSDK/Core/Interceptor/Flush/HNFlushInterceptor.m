//
// HNFlushInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNFlushInterceptor.h"
#import "HNHTTPSession.h"
#import "HNModuleManager.h"
#import "HNURLUtils.h"
#import "HNJSONUtil.h"
#import "HinaDataSDK+Private.h"
#import "HNLog.h"

NSString * const kHNFlushServerURL = @"serverURL";

#pragma mark -

@interface HNFlushInterceptor ()

@property (nonatomic, strong) dispatch_semaphore_t flushSemaphore;
@property (nonatomic, copy) NSString *serverURL;


@end

@implementation HNFlushInterceptor

+ (instancetype)interceptorWithParam:(NSDictionary *)param {
    HNFlushInterceptor *interceptor = [[HNFlushInterceptor alloc] init];
    interceptor.serverURL = param[kHNFlushServerURL];
    return interceptor;
}

- (dispatch_semaphore_t)flushSemaphore {
    if (!_flushSemaphore) {
        _flushSemaphore = dispatch_semaphore_create(0);
    }
    return _flushSemaphore;
}

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.configOptions || self.serverURL);
    NSParameterAssert(input.HTTPBody);

    // 当在程序终止或 debug 模式下，使用线程锁
    BOOL isWait = input.configOptions.flushBeforeEnterBackground || input.configOptions.debugMode != HinaDataDebugOff;
    [self requestWithInput:input completion:^(BOOL success) {
        input.flushSuccess = success;
        if (isWait) {
            dispatch_semaphore_signal(self.flushSemaphore);
        } else {
            completion(input);
        }
    }];
    if (isWait) {
        dispatch_semaphore_wait(self.flushSemaphore, DISPATCH_TIME_FOREVER);
        completion(input);
    }
}

#pragma mark - build
- (void)requestWithInput:(HNFlowData *)input completion:(void (^)(BOOL success))completion {
    // 网络请求回调处理
    HNURLSessionTaskCompletionHandler handler = ^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error || ![response isKindOfClass:[NSHTTPURLResponse class]]) {
            input.message = [NSString stringWithFormat:@"%@ network failure: %@", self, error ? error : @"Unknown error"];
            return completion(NO);
        }

        NSInteger statusCode = response.statusCode;

        NSString *urlResponseContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *messageDesc = nil;
        if (statusCode >= 200 && statusCode < 300) {
            messageDesc = @"\n【valid message】\n";
        } else {
            messageDesc = @"\n【invalid message】\n";
            if (statusCode >= 300 && input.configOptions.debugMode != HinaDataDebugOff) {
                NSString *errMsg = [NSString stringWithFormat:@"%@ flush failure with response '%@'.", self, urlResponseContent];
                [HNModuleManager.sharedInstance showDebugModeWarning:errMsg];
            }
        }

        NSDictionary *dict = [HNJSONUtil JSONObjectWithString:input.json];
        HNLogDebug(@"%@ %@: %@", self, messageDesc, dict);

        if (statusCode != 200) {
            HNLogError(@"%@ ret_code: %ld, ret_content: %@", self, statusCode, urlResponseContent);
        }

        input.statusCode = statusCode;
        // 1、开启 debug 模式，都删除；
        // 2、debugOff 模式下，只有 5xx & 404 & 403 不删，其余均删；
        BOOL successCode = (statusCode < 500 || statusCode >= 600) && statusCode != 404 && statusCode != 403;
        BOOL flushSuccess = input.configOptions.debugMode != HinaDataDebugOff || successCode;
        if (!flushSuccess) {
            input.message = [NSString stringWithFormat:@"flush failed, statusCode: %ld",statusCode];
        }
        completion(flushSuccess);
    };

    NSURLRequest *request = [self buildFlushRequestWithInput:input];
    NSURLSessionDataTask *task = [HNHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:handler];
    [task resume];
}

- (NSURLRequest *)buildFlushRequestWithInput:(HNFlowData *)input {
    NSString *urlString = self.serverURL ?: input.configOptions.serverURL;
    NSURL *serverURL = [HNURLUtils buildServerURLWithURLString:urlString debugMode:input.configOptions.debugMode];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:serverURL];
    request.timeoutInterval = 30;
    request.HTTPMethod = @"POST";
    request.HTTPBody = input.HTTPBody;
    // 普通事件请求，使用标准 UserAgent
    [request setValue:@"HinaData iOS SDK" forHTTPHeaderField:@"User-Agent"];
    //    @"application/json"😄
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if (input.configOptions.debugMode == HinaDataDebugOnly) {
        [request setValue:@"true" forHTTPHeaderField:@"Dry-Run"];
    }

    if (input.cookie) {
        [request setValue:input.cookie forHTTPHeaderField:@"Cookie"];
    }

    return request;
}

@end
