//
// HNURLUtils.h
// HinaDataSDK
//
// Created by hina on 2022/4/18.
/// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>
#import "HNConstants.h"

@interface HNURLUtils : NSObject

+ (NSString *)hostWithURL:(NSURL *)url;
+ (NSString *)hostWithURLString:(NSString *)URLString;

+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURL:(NSURL *)url;
+ (NSDictionary<NSString *, NSString *> *)queryItemsWithURLString:(NSString *)URLString;

+ (NSString *)urlQueryStringWithParams:(NSDictionary <NSString *, NSString *> *)params;

/// 解码并解析 URL 参数
/// @param url url 对象
+ (NSDictionary<NSString *, NSString *> *)decodeQueryItemsWithURL:(NSURL *)url;

+ (NSURL *)buildServerURLWithURLString:(NSString *)urlString debugMode:(HinaDataDebugMode)debugMode;
@end
