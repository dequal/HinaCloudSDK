//
// HNDynamicSuperPropertyPlugin.m
// HinaDataSDK
//
// Created by  hina on 2022/4/24.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDynamicSuperPropertyPlugin.h"
#import "HNSuperPropertyPlugin.h"
#import "HNPropertyPluginManager.h"
#import "HinaDataSDK+Private.h"
#import "HNReadWriteLock.h"
#import "HNPropertyValidator.h"

@interface HNDynamicSuperPropertyPlugin ()
/// 动态公共属性回调
@property (nonatomic, copy) HNDynamicSuperPropertyBlock dynamicSuperPropertyBlock;
/// 动态公共属性
@property (atomic, strong) NSDictionary *dynamicSuperProperties;

@property (nonatomic, strong) HNReadWriteLock *dynamicSuperPropertiesLock;
@end


@implementation HNDynamicSuperPropertyPlugin

+ (HNDynamicSuperPropertyPlugin *)sharedDynamicSuperPropertyPlugin {
    static HNDynamicSuperPropertyPlugin *propertyPlugin;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        propertyPlugin = [[HNDynamicSuperPropertyPlugin alloc] init];
    });
    return propertyPlugin;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *dynamicSuperPropertiesLockLabel = [NSString stringWithFormat:@"com.hinadata.dynamicSuperPropertiesLock.%p", self];
        _dynamicSuperPropertiesLock = [[HNReadWriteLock alloc] initWithQueueLabel:dynamicSuperPropertiesLockLabel];
    }
    return self;
}

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    return filter.type & HNEventTypeDefault;
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    return [self.dynamicSuperProperties copy];
}

#pragma mark - dynamicSuperProperties
- (void)registerDynamicSuperPropertiesBlock:(HNDynamicSuperPropertyBlock)dynamicSuperPropertiesBlock {
    [self.dynamicSuperPropertiesLock writeWithBlock:^{
        self.dynamicSuperPropertyBlock = dynamicSuperPropertiesBlock;
    }];
}

- (void)buildDynamicSuperProperties {
    [self.dynamicSuperPropertiesLock readWithBlock:^id _Nonnull{
        if (!self.dynamicSuperPropertyBlock) {
            return nil;
        }

        NSDictionary *dynamicProperties = self.dynamicSuperPropertyBlock();
        self.dynamicSuperProperties = [HNPropertyValidator validProperties:[dynamicProperties copy]];

        // 如果包含仅大小写不同的 key 注销对应 superProperties
        dispatch_async(HinaDataSDK.sdkInstance.serialQueue, ^{
            HNSuperPropertyPlugin *superPropertyPlugin = (HNSuperPropertyPlugin *)[HNPropertyPluginManager.sharedInstance pluginsWithPluginClass:HNSuperPropertyPlugin.class];
            if (superPropertyPlugin) {
                [superPropertyPlugin unregisterSameLetterSuperProperties:self.dynamicSuperProperties];
            }
        });

        return nil;
    }];
}

@end
