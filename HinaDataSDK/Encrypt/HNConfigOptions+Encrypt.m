//
// HNConfigOptions+Encrypt.m
// HinaDataSDK
//
// Created by hina on 2022/6/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNConfigOptions+Encrypt.h"

@interface HNConfigOptions ()

@property (atomic, strong, readwrite) NSMutableArray *encryptors;
@property (nonatomic, assign) BOOL enableEncrypt;
@property (nonatomic, copy) void (^saveSecretKey)(HNSecretKey * _Nonnull secretKey);
@property (nonatomic, copy) HNSecretKey * _Nonnull (^loadSecretKey)(void);

@end

@implementation HNConfigOptions (Encrypt)

- (void)registerEncryptor:(id<HNEncryptProtocol>)encryptor {
    if (![self isValidEncryptor:encryptor]) {
        NSString *format = @"\n You used a custom encryption plugin [ %@ ], but no encryption protocol related methods are implemented. Please correctly implement the related functions of the custom encryption plugin before running the project. \n";
        NSString *message = [NSString stringWithFormat:format, NSStringFromClass(encryptor.class)];
        NSAssert(NO, message);
        return;
    }
    if (!self.encryptors) {
        self.encryptors = [[NSMutableArray alloc] init];
    }
    [self.encryptors addObject:encryptor];
}

- (BOOL)isValidEncryptor:(id<HNEncryptProtocol>)encryptor {
    return ([encryptor respondsToSelector:@selector(symmetricEncryptType)] &&
            [encryptor respondsToSelector:@selector(asymmetricEncryptType)] &&
            [encryptor respondsToSelector:@selector(encryptEvent:)] &&
            [encryptor respondsToSelector:@selector(encryptSymmetricKeyWithPublicKey:)]);
}

@end
