//
// HNDeviceIDPropertyPlugin.m
// HinaDataSDK
//
// Created by hina on 2022/10/25.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDeviceIDPropertyPlugin.h"
#import "HNPropertyPluginManager.h"
#import "HNIdentifier.h"

NSString * const kHNDeviceIDPropertyPluginAnonymizationID = @"H_anonymization_id";
NSString *const kHNDeviceIDPropertyPluginDeviceID = @"H_device_id";

@implementation HNDeviceIDPropertyPlugin

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    return filter.type & HNEventTypeDefault;
}

- (HNPropertyPluginPriority)priority {
    return kHNPropertyPluginPrioritySuper;
}

- (void)prepare {
    NSString *hardwareID = [HNIdentifier hardwareID];
    NSData *data = [hardwareID dataUsingEncoding:NSUTF8StringEncoding];
    NSString *anonymizationID = [data base64EncodedStringWithOptions:0];

    [self readyWithProperties:self.disableDeviceId ? @{kHNDeviceIDPropertyPluginAnonymizationID: anonymizationID} : @{kHNDeviceIDPropertyPluginDeviceID: hardwareID}];
}

@end
