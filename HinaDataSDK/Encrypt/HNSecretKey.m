//
// HNSecretKey.m
// HinaDataSDK
//
// Created by hina on 2022/6/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNSecretKey.h"
#import "HNAlgorithmProtocol.h"

@interface HNSecretKey ()

/// 密钥版本
@property (nonatomic, assign) NSInteger version;

/// 密钥值
@property (nonatomic, copy) NSString *key;

/// 对称加密类型
@property (nonatomic, copy) NSString *symmetricEncryptType;

/// 非对称加密类型
@property (nonatomic, copy) NSString *asymmetricEncryptType;

@end

@implementation HNSecretKey

- (instancetype)initWithKey:(NSString *)key
                    version:(NSInteger)version
      asymmetricEncryptType:(NSString *)asymmetricEncryptType
       symmetricEncryptType:(NSString *)symmetricEncryptType {
    self = [super init];
    if (self) {
        self.version = version;
        self.key = key;
        [self updateAsymmetricType:asymmetricEncryptType symmetricType:symmetricEncryptType];

    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInteger:self.version forKey:@"version"];
    [coder encodeObject:self.key forKey:@"key"];
    [coder encodeObject:self.symmetricEncryptType forKey:@"symmetricEncryptType"];
    [coder encodeObject:self.asymmetricEncryptType forKey:@"asymmetricEncryptType"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.version = [coder decodeIntegerForKey:@"version"];
        self.key = [coder decodeObjectForKey:@"key"];

        NSString *symmetricType = [coder decodeObjectForKey:@"symmetricEncryptType"];
        NSString *asymmetricType = [coder decodeObjectForKey:@"asymmetricEncryptType"];
        [self updateAsymmetricType:asymmetricType symmetricType:symmetricType];
    }
    return self;
}

- (void)updateAsymmetricType:(NSString *)asymmetricType symmetricType:(NSString *)symmetricType {
    // 兼容老版本保存的秘钥
    if (!symmetricType) {
        self.symmetricEncryptType = kHNAlgorithmTypeAES;
    } else {
        self.symmetricEncryptType = symmetricType;
    }

    // 兼容老版本保存的秘钥
    if (!asymmetricType) {
        BOOL isECC = [self.key hasPrefix:kHNAlgorithmTypeECC];
        self.asymmetricEncryptType = isECC ? kHNAlgorithmTypeECC : kHNAlgorithmTypeRSA;
    } else {
        self.asymmetricEncryptType = asymmetricType;
    }
}

@end
