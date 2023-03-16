//
// HNEncryptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/23.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAlgorithmProtocol.h"

NSString * const kHNAlgorithmTypeAES = @"AES";
NSString * const kHNAlgorithmTypeRSA = @"RSA";
NSString * const kHNAlgorithmTypeECC = @"EC";
