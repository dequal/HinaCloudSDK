//
// HNUserAgent.m
// HinaDataSDK
//
// Created by hina on 2022/8/19.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNUserAgent.h"
#import <WebKit/WKWebView.h>
#import "HNLog.h"

@interface HNUserAgent ()

@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) dispatch_group_t loadUAGroup;
@property (nonatomic, copy) NSString* userAgent;

@end

@implementation HNUserAgent

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HNUserAgent *userAgent;
    dispatch_once(&onceToken, ^{
        userAgent = [[HNUserAgent alloc] init];
    });
    return userAgent;
}

+ (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion {
    [[HNUserAgent sharedInstance] loadUserAgentWithCompletion:completion];
}

- (void)loadUserAgentWithCompletion:(void (^)(NSString *))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.userAgent.length > 0) {
            completion(self.userAgent);
        } else if (self.wkWebView) {
            dispatch_group_notify(self.loadUAGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                completion(self.userAgent);
            });
        } else {
            self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
            self.loadUAGroup = dispatch_group_create();
            dispatch_group_enter(self.loadUAGroup);

            __weak typeof(self) weakSelf = self;
            [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id _Nullable response, NSError *_Nullable error) {
                __strong typeof(weakSelf) strongSelf = weakSelf;

                if (error || !response) {
                    HNLogError(@"WKWebView evaluateJavaScript load UA error:%@", error);
                    completion(nil);
                } else {
                    completion(response);
                    strongSelf.userAgent = response;
                }
                // 通过 wkWebView 控制 dispatch_group_leave 的次数
                if (strongSelf.wkWebView) {
                    dispatch_group_leave(strongSelf.loadUAGroup);
                }
                strongSelf.wkWebView = nil;
            }];
        }
    });
}

@end
