//
// HNECCPluginEncryptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNECCPluginEncryptor.h"
#import "HNAESEncryptor.h"
#import "HNECCEncryptor.h"

@interface HNECCPluginEncryptor ()

@property (nonatomic, strong) HNAESEncryptor *aesEncryptor;
@property (nonatomic, strong) HNECCEncryptor *eccEncryptor;

@end

@implementation HNECCPluginEncryptor

+ (BOOL)isAvaliable {
    return NSClassFromString(kHNEncryptECCClassName) != nil;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _aesEncryptor = [[HNAESEncryptor alloc] init];
        _eccEncryptor = [[HNECCEncryptor alloc] init];
    }
    return self;
}

- (NSString *)symmetricEncryptType {
    return [_aesEncryptor algorithm];
}

- (NSString *)asymmetricEncryptType {
    return [_eccEncryptor algorithm];
}

- (NSString *)encryptEvent:(NSData *)event {
    return [_aesEncryptor encryptData:event];
}

- (NSString *)encryptSymmetricKeyWithPublicKey:(NSString *)publicKey {
    if (![_eccEncryptor.key isEqualToString:publicKey]) {
        _eccEncryptor.key = publicKey;
    }
    return [_eccEncryptor encryptData:_aesEncryptor.key];
}

@end
