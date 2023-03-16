//
// HNFileStorePlugin.h
// HinaDataSDK
//
// Created by hina on 2022/12/1.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNStorePlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNFileStorePlugin : NSObject <HNStorePlugin>

+ (NSString *)filePath:(NSString *)key;

- (NSArray *)storeKeys;

@end

NS_ASSUME_NONNULL_END
