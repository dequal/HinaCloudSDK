//
// HNConfigOptions+Encrypt.h
// HinaDataSDK
//
// Created by hina on 2022/4/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNEncryptProtocol.h"
#import "HNConfigOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNConfigOptions (Encrypt)

/// 是否开启加密
@property (nonatomic, assign) BOOL enableEncrypt API_UNAVAILABLE(macos);

- (void)registerEncryptor:(id<HNEncryptProtocol>)encryptor API_UNAVAILABLE(macos);

/// 存储公钥的回调。务必保存秘钥所有字段信息
@property (nonatomic, copy) void (^saveSecretKey)(HNSecretKey * _Nonnull secretKey) API_UNAVAILABLE(macos);

/// 获取公钥的回调。务必回传秘钥所有字段信息
@property (nonatomic, copy) HNSecretKey * _Nonnull (^loadSecretKey)(void) API_UNAVAILABLE(macos);

@end

NS_ASSUME_NONNULL_END
