//
// HNEventTrackerPluginProtocol.h
// HinaDataSDK
//
// Created by hina on 2022/11/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HNEventTrackerPluginProtocol <NSObject>

//install plugin
- (void)install;

//uninstall plugin
- (void)uninstall;

@optional
//track event with properties
- (void)trackWithProperties:(NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
