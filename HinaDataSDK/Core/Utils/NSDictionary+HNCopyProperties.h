//
// NSDictionary+CopyProperties.h
// HinaDataSDK
//
// Created by hina on 2022/10/13.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (HNCopyProperties)

//use to safe copy event properties
- (NSDictionary *)hinadata_deepCopy;

@end

NS_ASSUME_NONNULL_END
