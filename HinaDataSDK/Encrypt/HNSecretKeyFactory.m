//
// HNSecretKeyFactory.m
// HinaDataSDK
//
// Created by hina on 2022/4/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNSecretKeyFactory.h"
#import "HNConfigOptions.h"
#import "HNSecretKey.h"
#import "HNValidator.h"
#import "HNJSONUtil.h"
#import "HNAlgorithmProtocol.h"
#import "HNECCPluginEncryptor.h"

static NSString *const kHNEncryptVersion = @"pkv";
static NSString *const kHNEncryptPublicKey = @"public_key";
static NSString *const kHNEncryptType = @"type";
static NSString *const kHNEncryptTypeSeparate = @"+";

@implementation HNSecretKeyFactory

#pragma mark - Encryptor Plugin 2.0
+ (HNSecretKey *)createSecretKeyByVersion2:(NSDictionary *)version2 {
    // key_v2 不存在时直接跳过 2.0 逻辑
    if (!version2) {
        return nil;
    }

    NSNumber *pkv = version2[kHNEncryptVersion];
    NSString *type = version2[kHNEncryptType];
    NSString *publicKey = version2[kHNEncryptPublicKey];

    // 检查相关参数是否有效
    if (!pkv || ![HNValidator isValidString:type] || ![HNValidator isValidString:publicKey]) {
        return nil;
    }

    NSArray *types = [type componentsSeparatedByString:kHNEncryptTypeSeparate];
    // 当 type 分隔数组个数小于 2 时 type 不合法，不处理秘钥信息
    if (types.count < 2) {
        return nil;
    }

    // 非对称加密类型，例如: SM2
    NSString *asymmetricType = types[0];

    // 对称加密类型，例如: SM4
    NSString *symmetricType = types[1];

    return [[HNSecretKey alloc] initWithKey:publicKey version:[pkv integerValue] asymmetricEncryptType:asymmetricType symmetricEncryptType:symmetricType];
}

+ (HNSecretKey *)createSecretKeyByVersion1:(NSDictionary *)version1 {
    if (!version1) {
        return nil;
    }
    // 1.0 历史版本逻辑，只处理 key 字段中内容
    NSString *eccContent = version1[@"key_ec"];

    // 当 key_ec 存在且加密库存在时，使用 EC 加密插件
    // 不论秘钥是否创建成功，都不再切换使用其他加密插件

    // 这里为了检查 ECC 插件是否存在，手动生成 ECC 模拟秘钥
    if (eccContent && [HNECCPluginEncryptor isAvaliable]) {
        NSDictionary *config = [HNJSONUtil JSONObjectWithString:eccContent];
        return [HNSecretKeyFactory createECCSecretKey:config];
    }

    // 当远程配置不包含自定义秘钥且 EC 不可用时，使用 RSA 秘钥
    return [HNSecretKeyFactory createRSASecretKey:version1];
}

#pragma mark - Encryptor Plugin 1.0
+ (HNSecretKey *)createECCSecretKey:(NSDictionary *)config {
    if (![HNValidator isValidDictionary:config]) {
        return nil;
    }
    NSNumber *pkv = config[kHNEncryptVersion];
    NSString *publicKey = config[kHNEncryptPublicKey];
    NSString *type = config[kHNEncryptType];
    if (!pkv || ![HNValidator isValidString:type] || ![HNValidator isValidString:publicKey]) {
        return nil;
    }
    NSString *key = [NSString stringWithFormat:@"%@:%@", type, publicKey];
    return [[HNSecretKey alloc] initWithKey:key version:[pkv integerValue] asymmetricEncryptType:type symmetricEncryptType:kHNAlgorithmTypeAES];
}

+ (HNSecretKey *)createRSASecretKey:(NSDictionary *)config {
    if (![HNValidator isValidDictionary:config]) {
        return nil;
    }
    NSNumber *pkv = config[kHNEncryptVersion];
    NSString *publicKey = config[kHNEncryptPublicKey];
    if (!pkv || ![HNValidator isValidString:publicKey]) {
        return nil;
    }
    return [[HNSecretKey alloc] initWithKey:publicKey version:[pkv integerValue] asymmetricEncryptType:kHNAlgorithmTypeRSA symmetricEncryptType:kHNAlgorithmTypeAES];
}

@end
