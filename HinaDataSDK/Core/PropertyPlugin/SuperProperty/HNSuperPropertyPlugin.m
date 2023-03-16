//
// HNSuperPropertyPlugin.m
// HinaDataSDK
//
// Created by  hina on 2022/4/22.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNSuperPropertyPlugin.h"
#import "HNPropertyValidator.h"
#import "HNStoreManager.h"
#import "HNEventLibObject.h"

static NSString *const kHNSavedSuperPropertiesFileName = @"super_properties";

@interface HNSuperPropertyPlugin ()
/// 静态公共属性
@property (atomic, strong) NSDictionary *superProperties;
@end


@implementation HNSuperPropertyPlugin

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    return filter.type & HNEventTypeDefault;
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityLow;
}

- (void)prepare {
    [self unarchiveSuperProperties];
}

- (NSDictionary<NSString *,id> *)properties {
    return [self.superProperties copy];
}

#pragma mark - superProperties
- (void)registerSuperProperties:(NSDictionary *)propertyDict {
    NSDictionary *validProperty = [HNPropertyValidator validProperties:[propertyDict copy]];
    [self unregisterSameLetterSuperProperties:validProperty];
    // 注意这里的顺序，发生冲突时是以 propertyDict 为准，所以它是后加入的
    NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.properties];
    [tmp addEntriesFromDictionary:validProperty];
    self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
    [self archiveSuperProperties];
}

- (void)unregisterSuperProperty:(NSString *)propertyKey {
    if (!propertyKey) {
        return;
    }
    NSMutableDictionary *superProperties = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
    [superProperties removeObjectForKey:propertyKey];
    self.superProperties = [NSDictionary dictionaryWithDictionary:superProperties];
    [self archiveSuperProperties];
}

- (void)clearSuperProperties {
    self.superProperties = @{};
    [self archiveSuperProperties];
}

/// 注销仅大小写不同的 SuperProperties
/// @param propertyDict 公共属性
- (void)unregisterSameLetterSuperProperties:(NSDictionary *)propertyDict {
    NSArray *allNewKeys = [propertyDict.allKeys copy];
    //如果包含仅大小写不同的 key ,unregisterSuperProperty
    NSArray *superPropertyAllKeys = [self.superProperties.allKeys copy];
    NSMutableArray *unregisterPropertyKeys = [NSMutableArray array];
    for (NSString *newKey in allNewKeys) {
        [superPropertyAllKeys enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *usedKey = (NSString *)obj;
            if ([usedKey caseInsensitiveCompare:newKey] == NSOrderedSame) { // 存在不区分大小写相同 key
                [unregisterPropertyKeys addObject:usedKey];
            }
        }];
    }
    if (unregisterPropertyKeys.count > 0) {
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.properties];
        [tmp removeObjectsForKeys:unregisterPropertyKeys];
        self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
    }
}

#pragma mark - 缓存

- (void)unarchiveSuperProperties {
    NSDictionary *archivedSuperProperties = [[HNStoreManager sharedInstance] objectForKey:kHNSavedSuperPropertiesFileName];
    self.superProperties = archivedSuperProperties ? [archivedSuperProperties copy] : [NSDictionary dictionary];
}

- (void)archiveSuperProperties {
    [[HNStoreManager sharedInstance] setObject:self.superProperties forKey:kHNSavedSuperPropertiesFileName];
}

@end
