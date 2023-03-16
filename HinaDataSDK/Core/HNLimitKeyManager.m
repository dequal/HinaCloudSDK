//
// HNLimitKeyManager.m
// HinaDataSDK
//
// Created by hina on 2022/10/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNLimitKeyManager.h"
#import "HNConstants.h"

@interface HNLimitKeyManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id> *keys;

@end

@implementation HNLimitKeyManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _keys = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HNLimitKeyManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNLimitKeyManager alloc] init];
    });
    return manager;
}

+ (void)registerLimitKeys:(NSDictionary<HNLimitKey, NSString *> *)keys {
    if (![keys isKindOfClass:[NSDictionary class]]) {
        return;
    }
    [[HNLimitKeyManager sharedInstance].keys addEntriesFromDictionary:[keys copy]];
}

+ (NSString *)idfa {
    return [HNLimitKeyManager sharedInstance].keys[HNLimitKeyIDFA];
}

+ (NSString *)idfv {
    return [HNLimitKeyManager sharedInstance].keys[HNLimitKeyIDFV];
}

+ (NSString *)carrier {
    return [HNLimitKeyManager sharedInstance].keys[HNLimitKeyCarrier];
}

@end
