//
// HNEventTrackerPluginManager.m
// HinaDataSDK
//
// Created by hina on 2022/11/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNEventTrackerPluginManager.h"

@interface HNEventTrackerPluginManager ()

@property (nonatomic, strong) NSMutableArray<HNEventTrackerPlugin<HNEventTrackerPluginProtocol> *> *plugins;

@end

@implementation HNEventTrackerPluginManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNEventTrackerPluginManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNEventTrackerPluginManager alloc] init];
    });
    return manager;
}

- (void)registerPlugin:(HNEventTrackerPlugin<HNEventTrackerPluginProtocol> *)plugin {
    //object basic check, nil、class and protocol
    if (![plugin isKindOfClass:[HNEventTrackerPlugin class]] || ![plugin conformsToProtocol:@protocol(HNEventTrackerPluginProtocol)]) {
        return;
    }

    //required protocol implementation check
    if (![plugin respondsToSelector:@selector(install)] || ![plugin respondsToSelector:@selector(uninstall)]) {
        return;
    }

    //duplicate check
    if ([self.plugins containsObject:plugin]) {
        return;
    }

    //same type plugin check
    [self.plugins enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(HNEventTrackerPlugin<HNEventTrackerPluginProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.type isEqualToString:plugin.type]) {
            [plugin uninstall];
            [self.plugins removeObject:obj];
            *stop = YES;
        }
    }];

    [self.plugins addObject:plugin];
    [plugin install];
}

- (void)unregisterPlugin:(Class)pluginClass {
    [self.plugins enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(HNEventTrackerPlugin<HNEventTrackerPluginProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:pluginClass] && [obj respondsToSelector:@selector(uninstall)]) {
            [obj uninstall];
            [self.plugins removeObject:obj];
            *stop = YES;
        }
    }];
}

- (void)unregisterAllPlugins {
    [self.plugins enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(HNEventTrackerPlugin<HNEventTrackerPluginProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(uninstall)]) {
            [obj uninstall];
            [self.plugins removeObject:obj];
        }
    }];
}

- (void)enableAllPlugins {
    for (HNEventTrackerPlugin<HNEventTrackerPluginProtocol> *plugin in self.plugins) {
        plugin.enable = YES;
    }
}

- (void)disableAllPlugins {
    for (HNEventTrackerPlugin<HNEventTrackerPluginProtocol> *plugin in self.plugins) {
        plugin.enable = NO;
    }
}

- (HNEventTrackerPlugin<HNEventTrackerPluginProtocol> *)pluginWithType:(NSString *)pluginType {
    for (HNEventTrackerPlugin<HNEventTrackerPluginProtocol> *plugin in self.plugins) {
        if ([plugin.type isEqualToString:pluginType]) {
            return plugin;
        }
    }
    return nil;
}

- (NSMutableArray<HNEventTrackerPlugin<HNEventTrackerPluginProtocol> *> *)plugins {
    if (!_plugins) {
        _plugins = [[NSMutableArray alloc] init];
    }
    return _plugins;
}

@end
