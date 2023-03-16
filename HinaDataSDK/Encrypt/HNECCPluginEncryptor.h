//
// HNECCPluginEncryptor.h
// HinaDataSDK
//
// Created by hina on 2022/4/14.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNEncryptProtocol.h"
#import "HNECCEncryptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNECCPluginEncryptor : NSObject <HNEncryptProtocol>

+ (BOOL)isAvaliable;

@end

NS_ASSUME_NONNULL_END
