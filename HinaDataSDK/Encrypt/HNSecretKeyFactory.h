//
// HNSecretKeyFactory.h
// HinaDataSDK
//
// Created by hina on 2022/4/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

@class HNSecretKey;

NS_ASSUME_NONNULL_BEGIN

@interface HNSecretKeyFactory : NSObject

typedef BOOL(^EncryptorChecker)(HNSecretKey *secretKey);

/// {  "key_v2": { "pkv": 27, "public_key": "<公钥>", "type": "SM2+SM4"} ,
///  "key ": { " pkv": 23, "public_key": "<公钥>", "key_ec":  "{ \"pkv\":26,\"type\":\"EC\",\"public_key\":\<公钥>\" }" } }

/// 根据 key_v2 秘钥信息生成对应的秘钥实例对象，加密插件化 2.0 逻辑
/// @param version2 key_v2 秘钥信息
/// @return 返回可用秘钥对象
+ (HNSecretKey *)createSecretKeyByVersion2:(NSDictionary *)version2;

/// 根据 key 秘钥信息生成对应的秘钥实例对象，加密插件化 1.0 逻辑
/// @param version1 key 版本秘钥信息
/// @return 返回可用秘钥对象
+ (HNSecretKey *)createSecretKeyByVersion1:(NSDictionary *)version1;

@end

NS_ASSUME_NONNULL_END
