//
// HNAESEncryptor.h
// HinaDataSDK
//
// Created by hina on 2022/12/12.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNAlgorithmProtocol.h"
#import "HNAESCrypt.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNAESEncryptor : HNAESCrypt <HNAlgorithmProtocol>

@end

NS_ASSUME_NONNULL_END
