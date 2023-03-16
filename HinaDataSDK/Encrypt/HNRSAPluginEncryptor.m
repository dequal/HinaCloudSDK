//
// HNRSAPluginEncryptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNRSAPluginEncryptor.h"
#import "HNAESEncryptor.h"
#import "HNRSAEncryptor.h"

@interface HNRSAPluginEncryptor ()

@property (nonatomic, strong) HNAESEncryptor *aesEncryptor;
@property (nonatomic, strong) HNRSAEncryptor *rsaEncryptor;

@end

@implementation HNRSAPluginEncryptor

- (instancetype)init {
    self = [super init];
    if (self) {
        _aesEncryptor = [[HNAESEncryptor alloc] init];
        _rsaEncryptor = [[HNRSAEncryptor alloc] init];
    }
    return self;
}

/// 返回对称加密的类型，例如 AES
- (NSString *)symmetricEncryptType {
    return [_aesEncryptor algorithm];
}

/// 返回非对称加密的类型，例如 RSA
- (NSString *)asymmetricEncryptType {
    return [_rsaEncryptor algorithm];
}

/// 返回加密后的事件数据
/// @param event gzip 压缩后的事件数据
- (NSString *)encryptEvent:(NSData *)event {
    return [_aesEncryptor encryptData:event];
}

/// 返回加密后的对称密钥数据
/// @param publicKey 非对称加密算法的公钥，用于加密对称密钥
- (NSString *)encryptSymmetricKeyWithPublicKey:(NSString *)publicKey {
    if (![_rsaEncryptor.key isEqualToString:publicKey]) {
        _rsaEncryptor.key = publicKey;
    }
    return [_rsaEncryptor encryptData:_aesEncryptor.key];
}

@end
