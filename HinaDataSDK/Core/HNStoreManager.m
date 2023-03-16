//
// HNStoreManager.m
// HinaDataSDK
//
// Created by hina on 2022/12/1.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNStoreManager.h"

@interface HNBaseStoreManager (HNPrivate)

@property (nonatomic, strong) NSMutableArray<id<HNStorePlugin>> *plugins;

@end

@implementation HNStoreManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HNStoreManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNStoreManager alloc] init];
    });
    return manager;
}

- (BOOL)isRegisteredCustomStorePlugin {
    // 默认情况下 SDK 只有两个存储插件
    return self.plugins.count > 2;
}

@end
