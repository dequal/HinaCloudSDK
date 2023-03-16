//
// HNAESCrypt.h
// HinaDataSDK
//
// Created by hina on 2022/12/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNAESCrypt : NSObject

@property (nonatomic, copy, readonly) NSData *key;

- (instancetype)initWithKey:(NSData *)key;

- (nullable NSString *)encryptData:(NSData *)data;
- (nullable NSData *)decryptData:(NSData *)obj;

@end

NS_ASSUME_NONNULL_END
