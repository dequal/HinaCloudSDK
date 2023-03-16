//
// HNCommonUtility.h
// HinaDataSDK
//
// Created by hina on 2022/7/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

@interface HNCommonUtility : NSObject

///按字节截取指定长度字符，包括汉字和表情
+ (NSString *)subByteString:(NSString *)string byteLength:(NSInteger )length;

/// 主线程执行
+ (void)performBlockOnMainThread:(DISPATCH_NOESCAPE dispatch_block_t)block;

/// 获取当前的 UserAgent
+ (NSString *)currentUserAgent;

/// 保存 UserAgent
+ (void)saveUserAgent:(NSString *)userAgent;

/// 计算 hash
+ (NSString *)hashStringWithData:(NSData *)data;


@end
