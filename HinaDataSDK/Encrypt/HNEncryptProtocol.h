//
// HNEncryptProtocol.h
// HinaDataSDK
//
// Created by hina on 2022/4/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

@protocol HNEncryptProtocol <NSObject>

/// 返回对称加密的类型，例如 AES
- (NSString *)symmetricEncryptType;

/// 返回非对称加密的类型，例如 RSA
- (NSString *)asymmetricEncryptType;

/// 返回压缩后的事件数据
/// @param event gzip 压缩后的事件数据
- (NSString *)encryptEvent:(NSData *)event;

/// 返回压缩后的对称密钥数据
/// @param publicKey 非对称加密算法的公钥，用于加密对称密钥
- (NSString *)encryptSymmetricKeyWithPublicKey:(NSString *)publicKey;

@end
