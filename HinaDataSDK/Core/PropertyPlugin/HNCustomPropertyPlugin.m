//
// HNCustomPropertyPlugin.m
// HinaDataSDK
//
// Created by  hina on 2022/5/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNCustomPropertyPlugin.h"
#import "HNValidator.h"
#import "HNPropertyValidator.h"
#import "HNConstants+Private.h"
#import "HNPropertyPlugin+HNPrivate.h"
#import "HNEventLibObject.h"

@interface HNCustomPropertyPlugin()
/// 校验前的自定义属性原始内容
@property (nonatomic, copy) NSDictionary<NSString *, id> *originalProperties;
@end

@implementation HNCustomPropertyPlugin

- (instancetype)initWithCustomProperties:(NSDictionary *)properties {
    self = [super init];
    if (self) {
        if ([HNValidator isValidDictionary:properties]) {
            self.originalProperties = properties;
        }
    }
    return self;
}

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    // item 和 profile 操作，也可能包含自定义属性
    return filter.type & HNEventTypeAll;
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityDefault;
}

- (NSDictionary<NSString *,id> *)properties {

    // 属性校验
    NSMutableDictionary *props = [HNPropertyValidator validProperties:self.originalProperties];
    // profile 和 item 操作，不包含 H_lib_method 属性
    // H5 打通事件，properties 中不包含 H_lib_method
    if (self.filter.type > HNEventTypeDefault || self.filter.hybridH5) {
        return [props copy];
    }

    if (!props) {
        props  = [NSMutableDictionary dictionary];
    }
    // 如果传入自定义属性中的 H_lib_method 为 String 类型，需要进行修正处理
    id libMethod = props[kHNEventPresetPropertyLibMethod];
    if ([self.filter.lib.method isEqualToString:kHNLibMethodAuto]) {
        libMethod = kHNLibMethodAuto;
    } else if (!libMethod || [libMethod isKindOfClass:NSString.class]) {
        if (![libMethod isEqualToString:kHNLibMethodCode] &&
            ![libMethod isEqualToString:kHNLibMethodAuto]) {
            libMethod = kHNLibMethodCode;
        }
    }
    props[kHNEventPresetPropertyLibMethod] = libMethod;
    
    return [props copy];
}
@end
