//
// HNNetwork.m
// HinaDataSDK
//
// Created by hina on 2022/3/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNNetwork.h"
#import "HNURLUtils.h"
#import "HNModuleManager.h"
#import "HinaDataSDK+Private.h"
#import "HinaDataSDK.h"
#import "NSString+HNHashCode.h"
#import "HNGzipUtility.h"
#import "HNLog.h"
#import "HNJSONUtil.h"
#import "HNHTTPSession.h"
#import "HNReachability.h"

#if TARGET_OS_IOS && !TARGET_OS_MACCATALYST
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#endif

@interface HNNetwork ()

@property (nonatomic, copy) NSString *cookie;

@end

@implementation HNNetwork

#pragma mark - cookie
- (void)setCookie:(NSString *)cookie isEncoded:(BOOL)encoded {
    if (encoded) {
        _cookie = [cookie stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]];
    } else {
        _cookie = cookie;
    }
}

- (NSString *)cookieWithDecoded:(BOOL)isDecoded {
    return isDecoded ? _cookie.stringByRemovingPercentEncoding : _cookie;
}

#pragma mark - build

#pragma mark - request


@end

#pragma mark -
@implementation HNNetwork (ServerURL)

- (NSURL *)serverURL {
    return [HNURLUtils buildServerURLWithURLString:HinaDataSDK.sdkInstance.configOptions.serverURL debugMode:HinaDataSDK.sdkInstance.configOptions.debugMode];
}

- (NSURLComponents *)baseURLComponents {
    if (self.serverURL.absoluteString.length <= 0) {
        return nil;
    }
    NSURLComponents *components;
    NSURL *url = self.serverURL.lastPathComponent.length > 0 ? [self.serverURL URLByDeletingLastPathComponent] : self.serverURL;
    if (url) {
        components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    }
    if (!components.host) {
        HNLogError(@"URLString is malformed, nil is returned.");
        return nil;
    }
    return components;
}

- (NSString *)host {
    return [HNURLUtils hostWithURL:self.serverURL] ?: @"";
}

- (NSString *)project {
    return [HNURLUtils queryItemsWithURL:self.serverURL][@"project"] ?: @"default";
}

- (NSString *)token {
    return [HNURLUtils queryItemsWithURL:self.serverURL][@"token"] ?: @"";
}

- (BOOL)isSameProjectWithURLString:(NSString *)URLString {
    if (![self isValidServerURL] || URLString.length == 0) {
        return NO;
    }
    BOOL isEqualHost = [self.host isEqualToString:[HNURLUtils hostWithURLString:URLString]];
    NSString *project = [HNURLUtils queryItemsWithURLString:URLString][@"project"] ?: @"default";
    BOOL isEqualProject = [self.project isEqualToString:project];
    return isEqualHost && isEqualProject;
}

- (BOOL)isValidServerURL {
    return self.serverURL.absoluteString.length > 0;
}

@end
