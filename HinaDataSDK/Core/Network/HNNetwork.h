//
// HNNetwork.h
// HinaDataSDK
//
// Created by hina on 2022/3/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>
#import "HinaDataSDK.h"
#import "HNSecurityPolicy.h"
#import "HNHTTPSession.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^HNURLSessionTaskCompletionHandler)(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error);

@interface HNNetwork : NSObject

/// debug mode
@property (nonatomic) HinaDataDebugMode debugMode;

/**
 * @abstract
 * 设置 Cookie
 *
 * @param cookie NSString cookie
 * @param encode BOOL 是否 encode
 */
- (void)setCookie:(NSString *)cookie isEncoded:(BOOL)encode;

/**
 * @abstract
 * 返回已设置的 Cookie
 *
 * @param decode BOOL 是否 decode
 * @return NSString cookie
 */
- (NSString *)cookieWithDecoded:(BOOL)decode;

@end

@interface HNNetwork (ServerURL)

@property (nonatomic, copy, readonly) NSURL *serverURL;
/// 通过 serverURL 获取的 host
@property (nonatomic, copy, readonly, nullable) NSString *host;
/// 在 serverURL 中获取的 project 名称
@property (nonatomic, copy, readonly, nullable) NSString *project;
/// 在 serverURL 中获取的 token 名称
@property (nonatomic, copy, readonly, nullable) NSString *token;

@property (nonatomic, copy, readonly, nullable) NSURLComponents *baseURLComponents;

- (BOOL)isSameProjectWithURLString:(NSString *)URLString;
- (BOOL)isValidServerURL;

@end

NS_ASSUME_NONNULL_END
