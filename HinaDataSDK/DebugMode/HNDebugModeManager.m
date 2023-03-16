//
// HNDebugModeManager.m
// HinaDataSDK
//
// Created by hina on 2022/11/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDebugModeManager.h"
#import "HNModuleManager.h"
#import "HinaDataSDK+Private.h"
#import "HNAlertController.h"
#import "HNURLUtils.h"
#import "HNJSONUtil.h"
#import "HNNetwork.h"
#import "HNLog.h"
#import "HNApplication.h"
#import "HNConstants+Private.h"

@interface HNDebugModeManager ()

@property (nonatomic) UInt8 debugAlertViewHasShownNumber;

@end

@implementation HNDebugModeManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNDebugModeManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNDebugModeManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _showDebugAlertView = YES;
        _debugAlertViewHasShownNumber = 0;
    }
    return self;
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    if ([HNApplication isAppExtension]) {
        configOptions.debugMode = HinaDataDebugOff;
    }
    _configOptions = configOptions;
    self.enable = configOptions.debugMode != HinaDataDebugOff;
}

- (BOOL)isEnable {
    if ([HNApplication isAppExtension]) {
        return NO;
    }
    return self.configOptions.debugMode != HinaDataDebugOff;
}

#pragma mark - HNOpenURLProtocol

- (BOOL)canHandleURL:(nonnull NSURL *)url {
    return [url.host isEqualToString:@"debugmode"];
}

- (BOOL)handleURL:(nonnull NSURL *)url {
    // url query 解析
    NSDictionary *paramDic = [HNURLUtils queryItemsWithURL:url];

    //如果没传 info_id，视为伪造二维码，不做处理
    if (paramDic.allKeys.count && [paramDic.allKeys containsObject:@"info_id"]) {
        [self showDebugModeAlertWithParams:paramDic];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - HNDebugModeModuleProtocol

- (void)showDebugModeWarning:(NSString *)message {
    [self showDebugModeWarning:message withNoMoreButton:YES];
}

#pragma mark - Private

- (void)showDebugModeAlertWithParams:(NSDictionary<NSString *, NSString *> *)params {
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_block_t alterViewBlock = ^{

            NSString *alterViewMessage = @"";
            if (self.configOptions.debugMode == HinaDataDebugAndTrack) {
                alterViewMessage = HNLocalizedString(@"HNDebugAndTrackModeTurnedOn");
            } else if (self.configOptions.debugMode == HinaDataDebugOnly) {
                alterViewMessage = HNLocalizedString(@"HNDebugOnlyModeTurnedOn");
            } else {
                alterViewMessage = HNLocalizedString(@"HNDebugModeTurnedOff");
            }
            HNAlertController *alertController = [[HNAlertController alloc] initWithTitle:@"" message:alterViewMessage preferredStyle:HNAlertControllerStyleAlert];
            [alertController addActionWithTitle:HNLocalizedString(@"HNAlertOK") style:HNAlertActionStyleCancel handler:nil];
            [alertController show];
        };

        NSString *alertTitle = HNLocalizedString(@"HNDebugMode");
        NSString *alertMessage = @"";
        if (self.configOptions.debugMode == HinaDataDebugAndTrack) {
            alertMessage = HNLocalizedString(@"HNDebugCurrentlyInDebugAndTrack");
        } else if (self.configOptions.debugMode == HinaDataDebugOnly) {
            alertMessage = HNLocalizedString(@"HNDebugCurrentlyInDebugOnly");
        } else {
            alertMessage = HNLocalizedString(@"HNDebugOff");
        }
        HNAlertController *alertController = [[HNAlertController alloc] initWithTitle:alertTitle message:alertMessage preferredStyle:HNAlertControllerStyleAlert];
        void(^handler)(HinaDataDebugMode) = ^(HinaDataDebugMode debugMode) {
            self.configOptions.debugMode = debugMode;
            alterViewBlock();
            [self debugModeCallbackWithDistinctId:[HinaDataSDK sharedInstance].distinctId params:params];
        };
        [alertController addActionWithTitle:HNLocalizedString(@"HNDebugAndTrack") style:HNAlertActionStyleDefault handler:^(HNAlertAction * _Nonnull action) {
            handler(HinaDataDebugAndTrack);
        }];
        [alertController addActionWithTitle:HNLocalizedString(@"HNDebugOnly") style:HNAlertActionStyleDefault handler:^(HNAlertAction * _Nonnull action) {
            handler(HinaDataDebugOnly);
        }];
        [alertController addActionWithTitle:HNLocalizedString(@"HNAlertCancel") style:HNAlertActionStyleCancel handler:nil];
        [alertController show];
    });
}

- (NSString *)debugModeToString:(HinaDataDebugMode)debugMode {
    NSString *modeStr = nil;
    switch (debugMode) {
        case HinaDataDebugOff:
            modeStr = @"DebugOff";
            break;
        case HinaDataDebugAndTrack:
            modeStr = @"DebugAndTrack";
            break;
        case HinaDataDebugOnly:
            modeStr = @"DebugOnly";
            break;
        default:
            modeStr = @"Unknown";
            break;
    }
    return modeStr;
}

- (void)showDebugModeWarning:(NSString *)message withNoMoreButton:(BOOL)showNoMore {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([HNModuleManager.sharedInstance isDisableSDK]) {
            return;
        }

        if (self.configOptions.debugMode == HinaDataDebugOff) {
            return;
        }

        if (!self.showDebugAlertView) {
            return;
        }

        if (self.debugAlertViewHasShownNumber >= 3) {
            return;
        }
        self.debugAlertViewHasShownNumber += 1;
        NSString *alertTitle = HNLocalizedString(@"HNDebugNotes");
        HNAlertController *alertController = [[HNAlertController alloc] initWithTitle:alertTitle message:message preferredStyle:HNAlertControllerStyleAlert];
        [alertController addActionWithTitle:HNLocalizedString(@"HNAlertOK") style:HNAlertActionStyleCancel handler:^(HNAlertAction * _Nonnull action) {
            self.debugAlertViewHasShownNumber -= 1;
        }];
        if (showNoMore) {
            [alertController addActionWithTitle:HNLocalizedString(@"HNAlertNotRemind") style:HNAlertActionStyleDefault handler:^(HNAlertAction * _Nonnull action) {
                self.showDebugAlertView = NO;
            }];
        }
        [alertController show];
    });
}

- (NSURL *)serverURL {
    return [HinaDataSDK sharedInstance].network.serverURL;
}

#pragma mark - Request

- (NSURL *)buildDebugModeCallbackURLWithParams:(NSDictionary<NSString *, NSString *> *)params {
    NSURLComponents *urlComponents = nil;
    NSString *sfPushCallbackUrl = params[@"sf_push_distinct_id"];
    NSString *infoId = params[@"info_id"];
    NSString *project = params[@"project"];
    if (sfPushCallbackUrl.length > 0 && infoId.length > 0 && project.length > 0) {
        NSURL *url = [NSURL URLWithString:sfPushCallbackUrl];
        urlComponents = [[NSURLComponents alloc] initWithURL:url resolvingAgainstBaseURL:NO];
        urlComponents.queryItems = @[[[NSURLQueryItem alloc] initWithName:@"project" value:project], [[NSURLQueryItem alloc] initWithName:@"info_id" value:infoId]];
        return urlComponents.URL;
    }
    urlComponents = [NSURLComponents componentsWithURL:self.serverURL resolvingAgainstBaseURL:NO];
    NSString *queryString = [HNURLUtils urlQueryStringWithParams:params];
    if (urlComponents.query.length) {
        urlComponents.query = [NSString stringWithFormat:@"%@&%@", urlComponents.query, queryString];
    } else {
        urlComponents.query = queryString;
    }
    return urlComponents.URL;
}

- (NSURLRequest *)buildDebugModeCallbackRequestWithURL:(NSURL *)url distinctId:(NSString *)distinctId {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 30;
    [request setHTTPMethod:@"POST"];
    [request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *callData = @{@"account_id": distinctId};
    NSString *jsonString = [HNJSONUtil stringWithJSONObject:callData];
    [request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];

    return request;
}

- (NSURLSessionTask *)debugModeCallbackWithDistinctId:(NSString *)distinctId params:(NSDictionary<NSString *, NSString *> *)params {
    if (self.serverURL.absoluteString.length == 0) {
        HNLogError(@"serverURL error，Please check the serverURL");
        return nil;
    }
    NSURL *url = [self buildDebugModeCallbackURLWithParams:params];
    if (!url) {
        HNLogError(@"callback url in debug mode was nil");
        return nil;
    }

    NSURLRequest *request = [self buildDebugModeCallbackRequestWithURL:url distinctId:distinctId];

    NSURLSessionDataTask *task = [HNHTTPSession.sharedInstance dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error) {
        NSInteger statusCode = response.statusCode;
        if (statusCode == 200) {
            HNLogDebug(@"config debugMode CallBack success");
        } else {
            HNLogError(@"config debugMode CallBack Faild statusCode：%ld，url：%@", (long)statusCode, url);
        }
    }];
    [task resume];
    return task;
}

@end
