//
// HNDeviceIDPropertyPlugin.h
// HinaDataSDK
//
// Created by hina on 2022/10/25.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kHNDeviceIDPropertyPluginAnonymizationID;
extern NSString * const kHNDeviceIDPropertyPluginDeviceID;

@interface HNDeviceIDPropertyPlugin : HNPropertyPlugin

@property (nonatomic, assign) BOOL disableDeviceId;

@end

NS_ASSUME_NONNULL_END
