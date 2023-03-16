//
// HNEventTrackerPluginManager.h
// HinaDataSDK
//
// Created by hina on 2022/11/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNEventTrackerPlugin.h"
#import "HNEventTrackerPluginProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNEventTrackerPluginManager : NSObject

+ (instancetype)defaultManager;

//register plugin and install
- (void)registerPlugin:(HNEventTrackerPlugin<HNEventTrackerPluginProtocol> *)plugin;
- (void)unregisterPlugin:(Class)pluginClass;
- (void)unregisterAllPlugins;

- (void)enableAllPlugins;
- (void)disableAllPlugins;

- (HNEventTrackerPlugin<HNEventTrackerPluginProtocol> *)pluginWithType:(NSString *)pluginType;

@end

NS_ASSUME_NONNULL_END
