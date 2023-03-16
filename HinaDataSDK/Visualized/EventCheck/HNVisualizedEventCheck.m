//
// HNVisualizedEventCheck.m
// HinaDataSDK
//
// Created by hina on 2022/3/22.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNVisualizedEventCheck.h"
#import "HNConstants+Private.h"
#import "HNEventIdentifier.h"
#import "HNLog.h"


@interface HNVisualizedEventCheck()
@property (nonatomic, strong) HNVisualPropertiesConfigSources *configSources;

/// 埋点校验缓存
@property (nonatomic, strong, readwrite) NSMutableDictionary <NSString *,NSMutableArray <NSDictionary *> *>* eventCheckCache;
@end

@implementation HNVisualizedEventCheck

- (instancetype)initWithConfigSources:(HNVisualPropertiesConfigSources *)configSources;
{
    self = [super init];
    if (self) {
        _configSources = configSources;
        _eventCheckCache = [NSMutableDictionary dictionary];
        [self setupListeners];
    }
    return self;
}


- (void)setupListeners {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(trackEvent:) name:HN_TRACK_EVENT_NOTIFICATION object:nil];
    [notificationCenter addObserver:self selector:@selector(trackEventFromH5:) name:HN_TRACK_EVENT_H5_NOTIFICATION object:nil];
}

- (void)trackEvent:(NSNotification *)notification {
    if (![notification.userInfo isKindOfClass:NSDictionary.class]) {
        return;
    }

    NSDictionary *trackEventInfo = [notification.userInfo copy];
    // 构造事件标识
    HNEventIdentifier *eventIdentifier = [[HNEventIdentifier alloc] initWithEventInfo:trackEventInfo];
    // App 埋点校验，只支持 H_AppClick 可视化全埋点事件
    if (![eventIdentifier.eventName isEqualToString:kHNEventNameAppClick]) {
        return;
    }

    // 查询事件配置，一个 H_AppClick 事件，可能命中多个配置
    NSArray <HNVisualPropertiesConfig *>*configs = [self.configSources propertiesConfigsWithEventIdentifier:eventIdentifier];
    if (!configs) {
        return;
    }

    for (HNVisualPropertiesConfig *config in configs) {
        if (!config.event) {
            continue;
        }
        HNLogDebug(@"Debug mode, matching to visualized event %@", config.eventName);
        [self cacheVisualEvent:config.eventName eventInfo:trackEventInfo];
    }
}

- (void)trackEventFromH5:(NSNotification *)notification {
    if (![notification.userInfo isKindOfClass:NSDictionary.class]) {
        return;
    }

    NSDictionary *trackEventInfo = notification.userInfo;
    // 构造事件标识
    HNEventIdentifier *eventIdentifier = [[HNEventIdentifier alloc] initWithEventInfo:trackEventInfo];
    //App 内嵌 H5 埋点校验，只支持 H_WebClick 可视化全埋点事件
    if (![eventIdentifier.eventName isEqualToString:kHNEventNameWebClick]) {
        return;
    }

    // 针对 H_WebClick 可视化全埋点事件，Web JS SDK 已做标记
    NSArray *webVisualEventNames = trackEventInfo[kHNEventProperties][kHNWebVisualEventName];
    if (!webVisualEventNames) {
        return;
    }
    // 移除标记
    [eventIdentifier.properties removeObjectForKey:kHNWebVisualEventName];

    // 缓存 H5 可视化全埋点事件
    for (NSString *eventName in webVisualEventNames) {
        [self cacheVisualEvent:eventName eventInfo:trackEventInfo];
    }
}

/// 缓存可视化全埋点事件
- (void)cacheVisualEvent:(NSString *)eventName eventInfo:(NSDictionary *)eventInfo {
    if (!eventName) {
        return;
    }
    // 保存当前事件
    NSMutableArray *eventInfos = self.eventCheckCache[eventName];
    if (!eventInfos) {
        eventInfos = [NSMutableArray array];
        self.eventCheckCache[eventName] = eventInfos;
    }

    NSMutableDictionary *visualEventInfo = [eventInfo mutableCopy];
    visualEventInfo[@"event_name"] = eventName;
    [eventInfos addObject:visualEventInfo];
}

- (NSArray<NSDictionary *> *)eventCheckResult {
    NSMutableArray *allEventResult = [NSMutableArray array];
    for (NSArray *events in self.eventCheckCache.allValues) {
        [allEventResult addObjectsFromArray:events];
    }
    return [allEventResult copy];
}

- (void)cleanEventCheckResult {
    [self.eventCheckCache removeAllObjects];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
