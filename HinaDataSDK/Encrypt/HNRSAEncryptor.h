//
// HNRSAEncryptor.h
// HinaDataSDK
//
// Created by hina on 2022/12/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNAlgorithmProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNRSAEncryptor : NSObject <HNAlgorithmProtocol>

@property (nonatomic, copy) NSString *key;

@end

NS_ASSUME_NONNULL_END
