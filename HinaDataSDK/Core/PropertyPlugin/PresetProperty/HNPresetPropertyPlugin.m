//
// HNPresetPropertyPlugin.m
// HinaDataSDK
//
// Created by hina on 2022/9/7.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNPresetPropertyPlugin.h"
#import "HNPresetPropertyObject.h"
#import "HNEventLibObject.h"

@interface HNPresetPropertyPlugin ()

@property (nonatomic, copy) NSString *libVersion;

/// 完整预置属性
@property (nonatomic, copy) NSDictionary *presetProperties;

@end

@implementation HNPresetPropertyPlugin

- (instancetype)initWithLibVersion:(NSString *)libVersion {
    self = [super init];
    if (self) {
        _libVersion = libVersion;
    }
    return self;
}

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    return filter.type & HNEventTypeDefault;
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityLow;
}

/// 初始化预置属性
- (void)prepare {
    HNPresetPropertyObject *propertyObject;
#if TARGET_OS_IOS
    if ([self isiOSAppOnMac]) {
        propertyObject = [[HNCatalystPresetProperty alloc] init];
    } else {
        propertyObject = [[HNPhonePresetProperty alloc] init];
    }
#elif TARGET_OS_OSX
    propertyObject = [[HNMacPresetProperty alloc] init];
#endif

    NSMutableDictionary<NSString *, id> *properties = [NSMutableDictionary dictionary];
    [properties addEntriesFromDictionary:propertyObject.properties];
    properties[kHNEventPresetPropertyLibVersion] = self.libVersion;

    self.presetProperties = [properties copy];
}

- (NSDictionary<NSString *,id> *)properties {
    if (!self.filter.hybridH5) {
        return self.presetProperties;
    }

    // App 内嵌 H5 事件，H_lib 和  H_lib_version 使用 JS 的原始数据
    NSMutableDictionary *webPresetProperties = [self.presetProperties mutableCopy];
    [webPresetProperties removeObjectsForKeys:@[kHNEventPresetPropertyLib, kHNEventPresetPropertyLibVersion]];
    return [webPresetProperties copy];
}

#if TARGET_OS_IOS
- (BOOL)isiOSAppOnMac {
    NSProcessInfo *info = [NSProcessInfo processInfo];
    if (@available(iOS 14.0, macOS 11.0, *)) {
        if ([info respondsToSelector:@selector(isiOSAppOnMac)] &&
            info.isiOSAppOnMac) {
            return YES;
        }
    }
    if (@available(iOS 13.0, macOS 10.15, *)) {
        if ([info respondsToSelector:@selector(isMacCatalystApp)] &&
            info.isMacCatalystApp) {
            return YES;
        }
    }
    return NO;
}
#endif

@end
