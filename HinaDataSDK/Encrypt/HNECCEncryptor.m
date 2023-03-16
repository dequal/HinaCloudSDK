//
// HNECCEncryptor.m
// HinaDataSDK
//
// Created by hina on 2022/12/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNECCEncryptor.h"
#import "HNValidator.h"
#import "HNLog.h"

NSString * const kHNEncryptECCClassName = @"HNCryptoppECC";
NSString * const kHNEncryptECCPrefix = @"EC:";

typedef NSString* (*HNEEncryptImplementation)(Class, SEL, NSString *, NSString *);

@implementation HNECCEncryptor

- (void)setKey:(NSString *)key {
    if (![HNValidator isValidString:key]) {
        HNLogError(@"Enable ECC encryption but the secret key is invalid!");
        return;
    }

    // 兼容老版本逻辑，当前缀包含 EC: 时删除前缀信息
    if ([key hasPrefix:kHNEncryptECCPrefix]) {
        _key = [key substringFromIndex:[kHNEncryptECCPrefix length]];
    } else {
        _key = key;
    }
}

#pragma mark - Public Methods
- (NSString *)encryptData:(NSData *)obj {
    if (![HNValidator isValidData:obj]) {
        HNLogError(@"Enable ECC encryption but the input obj is invalid!");
        return nil;
    }

    // 去除非对称秘钥公钥中的前缀内容，返回实际的非对称秘钥公钥内容
    NSString *asymmetricKey = self.key;
    if (![HNValidator isValidString:asymmetricKey]) {
        HNLogError(@"Enable ECC encryption but the public key is invalid!");
        return nil;
    }
    
    Class class = NSClassFromString(kHNEncryptECCClassName);
    SEL selector = NSSelectorFromString(@"encrypt:withPublicKey:");
    IMP methodIMP = [class methodForSelector:selector];
    if (methodIMP) {
        NSString *string = [[NSString alloc] initWithData:obj encoding:NSUTF8StringEncoding];
        return ((HNEEncryptImplementation)methodIMP)(class, selector, string, asymmetricKey);
    }
    
    return nil;
}

- (NSString *)algorithm {
    return kHNAlgorithmTypeECC;
}

@end
