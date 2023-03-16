//
// HNDeviceWhiteList.m
// HinaDataSDK
//
// Created by hina on 2022/7/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDeviceWhiteList.h"
#import "HNAlertController.h"
#import "HNURLUtils.h"
#import "HinaDataSDK+Private.h"
#import "HNJSONUtil.h"
#import "HNIdentifier.h"
#import "HNConstants+Private.h"


static NSString * const kHNDeviceWhiteListHost = @"adsScanDeviceInfo";
static NSString * const kHNDeviceWhiteListQueryParamProjectName = @"project";
static NSString * const kHNDeviceWhiteListQueryParamInfoId = @"info_id";
static NSString * const kHNDeviceWhiteListQueryParamDeviceType = @"device_type";
static NSString * const kHNDeviceWhiteListQueryParamApiUrl = @"apiurl";

@implementation HNDeviceWhiteList

- (BOOL)canHandleURL:(NSURL *)url {
    return [url.host isEqualToString:kHNDeviceWhiteListHost];
}

- (BOOL)handleURL:(NSURL *)url {
    NSDictionary *query = [HNURLUtils decodeQueryItemsWithURL:url];
    if (!query) {
        return NO;
    }
    NSString *projectName = query[kHNDeviceWhiteListQueryParamProjectName];
    if (![projectName isEqualToString:[HinaDataSDK sdkInstance].network.project]) {
        [self showAlertWithMessage:HNLocalizedString(@"HNDeviceWhiteListMessageProject")];
        return NO;
    }
    NSString *deviceType = query[kHNDeviceWhiteListQueryParamDeviceType];
    //1 iOS，2 Android
    if (![deviceType isEqualToString:@"1"]) {
        [self showAlertWithMessage:HNLocalizedString(@"HNDeviceWhiteListMessageDeviceType")];
        return NO;
    }
    NSString *apiUrlString = query[kHNDeviceWhiteListQueryParamApiUrl];
    if (!apiUrlString) {
        return NO;
    }
    NSURL *apiUrl = [NSURL URLWithString:apiUrlString];
    if (!apiUrl) {
        return NO;
    }

    NSString *infoId = query[kHNDeviceWhiteListQueryParamInfoId];
    NSDictionary *params = @{kHNDeviceWhiteListQueryParamInfoId: infoId,
                             kHNDeviceWhiteListQueryParamDeviceType:@"1",
                             @"project_name":projectName,
                             @"ios_idfa":[HNIdentifier idfa] ? : @"",
                             @"ios_idfv": [HNIdentifier idfv] ? : @""};
    [self addWhiteListWithUrl:apiUrl params:params];
    return YES;
}

- (void)showAlertWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        HNAlertController *alert = [[HNAlertController alloc] initWithTitle:HNLocalizedString(@"HNDeviceWhiteListTitle") message:message preferredStyle:HNAlertControllerStyleAlert];
        [alert addActionWithTitle:HNLocalizedString(@"HNAlertOK") style:HNAlertActionStyleDefault handler:nil];
        [alert show];
    });
}

- (void)addWhiteListWithUrl:(NSURL *)url params:(NSDictionary *)params {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 30;
    request.HTTPBody = [HNJSONUtil dataWithJSONObject:params];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionDataTask *task = [[HNHTTPSession sharedInstance] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        //HTTP Status 200 and code 0
        if (response.statusCode == 200) {
            NSDictionary *result = [HNJSONUtil JSONObjectWithData:data];
            if ([result isKindOfClass:[NSDictionary class]] &&
                [result[@"code"] isKindOfClass:[NSNumber class]] &&
                [result[@"code"] integerValue] == 0) {
                [self showAlertWithMessage:HNLocalizedString(@"HNDeviceWhiteListMessageRequestSuccess")];
                return;
            }
        }
        [self showAlertWithMessage:HNLocalizedString(@"HNDeviceWhiteListMessageRequestFailure")];
    }];
    [task resume];
}

@end
