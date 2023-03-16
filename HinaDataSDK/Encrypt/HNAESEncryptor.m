//
// HNAESEncryptor.m
// HinaDataSDK
//
// Created by hina on 2022/12/12.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAESEncryptor.h"
#import <CommonCrypto/CommonCryptor.h>
#import "HNValidator.h"
#import "HNLog.h"

@implementation HNAESEncryptor

#pragma mark - Public Methods

- (NSString *)algorithm {
    return kHNAlgorithmTypeAES;
}

- (nullable NSString *)encryptData:(NSData *)obj {
    if (![HNValidator isValidData:obj]) {
        HNLogError(@"Enable AES encryption but the input obj is invalid!");
        return nil;
    }

    if (![HNValidator isValidData:self.key]) {
        HNLogError(@"Enable AES encryption but the secret key data is invalid!");
        return nil;
    }

    return [super encryptData:obj];
}

@end
