//
// HNEncryptor.h
// HinaDataSDK
//
// Created by hina on 2022/4/23.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kHNAlgorithmTypeAES;
extern NSString * const kHNAlgorithmTypeRSA;
extern NSString * const kHNAlgorithmTypeECC;

@protocol HNAlgorithmProtocol <NSObject>

- (nullable NSString *)encryptData:(NSData *)data;
- (NSString *)algorithm;

@end

NS_ASSUME_NONNULL_END
