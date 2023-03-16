//
// HNPropertyInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/13.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNPropertyInterceptor.h"
#import "HNPropertyPluginManager.h"
#import "HNModuleManager.h"
#import "HNConstants+Private.h"
#import "HNCustomPropertyPlugin.h"
#import "HNSuperPropertyPlugin.h"
#import "HNDeviceIDPropertyPlugin.h"
#import "HNLog.h"

@implementation HNPropertyInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);

    // 注册自定义属性采集插件，采集 track 附带属性
    HNCustomPropertyPlugin *customPlugin = [[HNCustomPropertyPlugin alloc] initWithCustomProperties:input.properties];
    [[HNPropertyPluginManager sharedInstance] registerCustomPropertyPlugin:customPlugin];

    HNBaseEventObject *object = input.eventObject;
    // 获取插件采集的所有属性
    NSDictionary *pluginProperties = [[HNPropertyPluginManager sharedInstance] propertiesWithFilter:object];
    // 属性合法性校验
    NSMutableDictionary *properties = [HNPropertyValidator validProperties:pluginProperties];

    // 事件、公共属性和动态公共属性都需要支持修改 H_project, H_token, H_time
    object.project = (NSString *)properties[kHNEventCommonOptionalPropertyProject];
    object.token = (NSString *)properties[kHNEventCommonOptionalPropertyToken];
    id originalTime = properties[kHNEventCommonOptionalPropertyTime];

    // App 内嵌 H5 自定义 time 在初始化中单独处理
    if ([originalTime isKindOfClass:NSDate.class] && !object.hybridH5) {
        NSDate *customTime = (NSDate *)originalTime;
        int64_t customTimeInt = [customTime timeIntervalSince1970] * 1000;
        if (customTimeInt >= kHNEventCommonOptionalPropertyTimeInt) {
            object.time = customTimeInt;
        } else {
            HNLogError(@"H_time error %lld, Please check the value", customTimeInt);
        }
    } else if (originalTime && !object.hybridH5) {
        HNLogError(@"H_time '%@' invalid, Please check the value", originalTime);
    }

    // H_project, H_token, H_time 处理完毕后需要移除
    NSArray<NSString *> *needRemoveKeys = @[kHNEventCommonOptionalPropertyProject,
                                            kHNEventCommonOptionalPropertyToken,
                                            kHNEventCommonOptionalPropertyTime];
    [properties removeObjectsForKeys:needRemoveKeys];

    // 公共属性, 动态公共属性, 自定义属性不允许修改 H_anonymization_id、H_device_id 属性, 因此需要将修正逻操作放在所有属性添加后
    if (input.configOptions.disableDeviceId) {
        // 不允许客户设置 H_device_id
        [properties removeObjectForKey:kHNDeviceIDPropertyPluginDeviceID];
    } else {
        // 不允许客户设置 H_anonymization_id
        [properties removeObjectForKey:kHNDeviceIDPropertyPluginAnonymizationID];
    }

    [object.properties addEntriesFromDictionary:[properties copy]];

    // 从公共属性中更新 lib 节点中的 H_app_version 值
    NSDictionary *superProperties = [HNPropertyPluginManager.sharedInstance currentPropertiesForPluginClasses:@[HNSuperPropertyPlugin.class]];
    id appVersion = superProperties[kHNEventPresetPropertyAppVersion];
    if (appVersion) {
        object.lib.appVersion = appVersion;
    }

    // 仅在全埋点的元素点击和页面浏览事件中添加 H_lib_detail
    BOOL isAppClick = [object.event isEqualToString:kHNEventNameAppClick];
    BOOL isViewScreen = [object.event isEqualToString:kHNEventNameAppViewScreen];
    NSDictionary *customProperties = [customPlugin properties];
    if (isAppClick || isViewScreen) {
        object.lib.detail = [NSString stringWithFormat:@"%@######", customProperties[kHNEventPropertyScreenName] ?: @""];
    }

    // 针对 Flutter 和 RN 触发的全埋点事件，需要修正 H_lib_method
    NSString *libMethod = input.properties[kHNEventPresetPropertyLibMethod];
    if ([libMethod isKindOfClass:NSString.class] && [libMethod isEqualToString:kHNLibMethodAuto] ) {
        object.lib.method = kHNLibMethodAuto;
    }

    input.properties = nil;
    completion(input);
}

@end
