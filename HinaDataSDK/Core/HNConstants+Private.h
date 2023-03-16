//
// HNConstants+Private.h
// HinaDataSDK
//
// Created by hina on 2022/4/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>
#import "HNConstants.h"

#pragma mark - Track Timer
extern NSString * const kHNEventIdSuffix;

#pragma mark--evnet
extern NSString * const kHNEventTime;
extern NSString * const kHNEventTrackId;
extern NSString * const kHNEventName;
extern NSString * const kHNEventDistinctId;
extern NSString * const kHNEventOriginalId;
extern NSString * const kHNEventProperties;
extern NSString * const kHNEventType;
extern NSString * const kHNEventLib;
extern NSString * const kHNEventProject;
extern NSString * const kHNEventToken;
extern NSString * const kHNEventHybridH5;
extern NSString * const kHNEventLoginId;
extern NSString * const kHNEvent_distinct_id;
extern NSString * const kHNEventIdentities;

#pragma mark - Item
extern NSString * const kHNEventItemSet;
extern NSString * const kHNEventItemDelete;

#pragma mark--evnet nanme

// App 启动或激活
extern NSString * const kHNEventNameAppStart;
// App 退出或进入后台
extern NSString * const kHNEventNameAppEnd;
// App 浏览页面
extern NSString * const kHNEventNameAppViewScreen;
// App 元素点击
extern NSString * const kHNEventNameAppClick;
/// Web 元素点击
extern NSString * const kHNEventNameWebClick;
// 自动追踪相关事件及属性
extern NSString * const kHNEventNameAppStartPassively;

extern NSString * const kHNEventNameSignUp;

extern NSString * const kHNEventNameAppCrashed;

extern NSString * const kHNEventNameAppRemoteConfigChanged;

// 绑定事件
extern NSString * const kHNEventNameBind;
// 解绑事件
extern NSString * const kHNEventNameUnbind;

#pragma mark--app install property
extern NSString * const kHNEventPropertyInstallSource;
extern NSString * const kHNEventPropertyInstallDisableCallback;
extern NSString * const kHNEventPropertyAppInstallFirstVisitTime;

#pragma mark--autoTrack property
// App 浏览页面 Url
extern NSString * const kHNEventPropertyScreenUrl;
// App 浏览页面 Referrer Url
extern NSString * const kHNEventPropertyScreenReferrerUrl;
extern NSString * const kHNEventPropertyElementId;
extern NSString * const kHNEventPropertyScreenName;
extern NSString * const kHNEventPropertyTitle;
extern NSString * const kHNEventPropertyElementPosition;
extern NSString * const kHNEventPropertyElementPath;
extern NSString * const kHNEventPropertyElementContent;
extern NSString * const kHNEventPropertyElementType;
extern NSString * const kHNEeventPropertyReferrerTitle;

// 远程控制配置信息
extern NSString * const kHNEventPropertyAppRemoteConfig;

#pragma mark--common property
//可选参数
extern NSString * const kHNEventCommonOptionalPropertyProject;
extern NSString * const kHNEventCommonOptionalPropertyToken;
extern NSString * const kHNEventCommonOptionalPropertyTime;
extern int64_t const kHNEventCommonOptionalPropertyTimeInt;

#pragma mark--lib method
extern NSString * const kHNLibMethodAuto;
extern NSString * const kHNLibMethodCode;

#pragma mark--track
extern NSString * const kHNEventTypeTrack;
extern NSString * const kHNEventTypeSignup;
extern NSString * const kHNEventTypeBind;
extern NSString * const kHNEventTypeUnbind;

#pragma mark--profile
extern NSString * const kHNProfileSet;
extern NSString * const kHNProfileSetOnce;
extern NSString * const kHNProfileUnset;
extern NSString * const kHNProfileDelete;
extern NSString * const kHNProfileAppend;
extern NSString * const kHNProfileIncrement;

#pragma mark - bridge name
extern NSString * const HN_SCRIPT_MESHNGE_HANDLER_NAME;

#pragma mark - reserved property list
NSSet* hinadata_reserved_properties(void);

#pragma mark - safe sync
BOOL hinadata_is_same_queue(dispatch_queue_t queue);

void hinadata_dispatch_safe_sync(dispatch_queue_t queue,
                                    DISPATCH_NOESCAPE dispatch_block_t block);

#pragma mark - Localization
NSString* hinadata_localized_string(NSString* key, NSString* value);

#define HNLocalizedString(key) \
        hinadata_localized_string((key), @"")
#define HNLocalizedStringWithDefaultValue(key, value) \
        hinadata_localized_string((key), (value))

#pragma mark - SF related notifications
extern NSNotificationName const HN_TRACK_EVENT_NOTIFICATION;
extern NSNotificationName const HN_TRACK_LOGIN_NOTIFICATION;
extern NSNotificationName const HN_TRACK_LOGOUT_NOTIFICATION;
extern NSNotificationName const HN_TRACK_IDENTIFY_NOTIFICATION;
extern NSNotificationName const HN_TRACK_RESETANONYMOUSID_NOTIFICATION;
extern NSNotificationName const HN_TRACK_EVENT_H5_NOTIFICATION;

#pragma mark - ABTest related notifications
/// 注入打通 bridge
extern NSNotificationName const HN_H5_BRIDGE_NOTIFICATION;

/// H5 通过 postMessage 发送消息
extern NSNotificationName const HN_H5_MESHNGE_NOTIFICATION;

#pragma mark - HN notifications
extern NSNotificationName const HN_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION;

/// 接收 App 内嵌 H5 可视化相关页面元素信息
extern NSNotificationName const kHNVisualizedMessageFromH5Notification;

// page leave
extern NSString * const kHNEventDurationProperty;
extern NSString * const kHNEventNameAppPageLeave;


//event name、property key、value max length
extern NSInteger kHNEventNameMaxLength;
extern NSInteger kHNPropertyValueMaxLength;

#pragma mark - HN Visualized
/// H5 可视化全埋点事件标记
extern NSString * const kHNWebVisualEventName;
/// 内嵌 H5 可视化全埋点 App 自定义属性配置
extern NSString * const kHNAppVisualProperties;
/// 内嵌 H5 可视化全埋点 Web 自定义属性配置
extern NSString * const kHNWebVisualProperties;

/// is instant event
extern NSString * const kHNInstantEventKey;
