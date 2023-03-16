//
// HNConstants.m
// HinaDataSDK
//
// Created by hina on 2022/8/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNConstants.h"
#import "HNConstants+Private.h"
#import "HinaDataSDK+Private.h"

#pragma mark - Track Timer
NSString *const kHNEventIdSuffix = @"_HNTimer";

#pragma mark - event
NSString * const kHNEventTime = @"time";
NSString * const kHNEventTrackId = @"_track_id";
NSString * const kHNEventName = @"event";

//NSString * const kHNEventDistinctId = @"distinct_id";  //替换account_id
//NSString * const kHNEventAccountId = @"account_id";
NSString * const kHNEventDistinctId = @"account_id";  //替换account_id

NSString * const kHNEventOriginalId = @"original_id";
NSString * const kHNEventProperties = @"attr";
NSString * const kHNEventType = @"type";
NSString * const kHNEventLib = @"lib";
NSString * const kHNEventProject = @"project";
NSString * const kHNEventToken = @"token";
NSString * const kHNEventHybridH5 = @"_hybrid_h5";
NSString * const kHNEventLoginId = @"login_id";

//NSString * const kHNEventAnonymousId = @"anonymous_id"; //替换distinct_id
NSString * const kHNEvent_distinct_id = @"distinct_id";

NSString * const kHNEventIdentities = @"user";

#pragma mark - Item
NSString * const kHNEventItemSet = @"item_set";
NSString * const kHNEventItemDelete = @"item_delete";

#pragma mark - event name
// App 启动或激活
NSString * const kHNEventNameAppStart = @"H_AppStart";
// App 退出或进入后台
NSString * const kHNEventNameAppEnd = @"H_AppEnd";
// App 浏览页面
NSString * const kHNEventNameAppViewScreen = @"H_AppViewScreen";
// App 元素点击
NSString * const kHNEventNameAppClick = @"H_AppClick";
// web 元素点击
NSString * const kHNEventNameWebClick = @"H_WebClick";

// 自动追踪相关事件及属性
NSString * const kHNEventNameAppStartPassively = @"H_AppStartPassively";

NSString * const kHNEventNameSignUp = @"H_SignUp";

NSString * const kHNEventNameAppCrashed = @"AppCrashed";
// 远程控制配置变化
NSString * const kHNEventNameAppRemoteConfigChanged = @"H_AppRemoteConfigChanged";

// 绑定事件
NSString * const kHNEventNameBind = @"H_BindID";
// 解绑事件
NSString * const kHNEventNameUnbind = @"H_UnbindID";

#pragma mark - app install property
NSString * const kHNEventPropertyInstallSource = @"H_ios_install_source";
NSString * const kHNEventPropertyInstallDisableCallback = @"H_ios_install_disable_callback";
NSString * const kHNEventPropertyAppInstallFirstVisitTime = @"H_first_visit_time";
#pragma mark - autoTrack property
// App 浏览页面 Url
NSString * const kHNEventPropertyScreenUrl = @"H_url";
// App 浏览页面 Referrer Url
NSString * const kHNEventPropertyScreenReferrerUrl = @"H_referrer";
NSString * const kHNEventPropertyElementId = @"H_element_id";
NSString * const kHNEventPropertyScreenName = @"H_screen_name";
NSString * const kHNEventPropertyTitle = @"H_title";
NSString * const kHNEventPropertyElementPosition = @"H_element_position";

NSString * const kHNEeventPropertyReferrerTitle = @"H_referrer_title";

// 模糊路径
NSString * const kHNEventPropertyElementPath = @"H_element_path";
NSString * const kHNEventPropertyElementContent = @"H_element_content";
NSString * const kHNEventPropertyElementType = @"H_element_type";
// 远程控制配置信息
NSString * const kHNEventPropertyAppRemoteConfig = @"H_app_remote_config";

#pragma mark - common property
NSString * const kHNEventCommonOptionalPropertyProject = @"H_project";
NSString * const kHNEventCommonOptionalPropertyToken = @"H_token";
NSString * const kHNEventCommonOptionalPropertyTime = @"H_time";
//海纳成立时间，2015-05-15 10:24:00.000，某些时间戳判断（毫秒）
int64_t const kHNEventCommonOptionalPropertyTimeInt = 1431656640000;

#pragma mark--lib method
NSString * const kHNLibMethodAuto = @"autoTrack";
NSString * const kHNLibMethodCode = @"code";

#pragma mark--track type
NSString * const kHNEventTypeTrack = @"track";
NSString * const kHNEventTypeSignup = @"track_signup";
NSString * const kHNEventTypeBind = @"track_id_bind";
NSString * const kHNEventTypeUnbind = @"track_id_unbind";

#pragma mark - profile
NSString * const kHNProfileSet = @"profile_set";
NSString * const kHNProfileSetOnce = @"profile_set_once";
NSString * const kHNProfileUnset = @"profile_unset";
NSString * const kHNProfileDelete = @"profile_delete";
NSString * const kHNProfileAppend = @"profile_append";
NSString * const kHNProfileIncrement = @"profile_increment";

#pragma mark - bridge name
NSString * const HN_SCRIPT_MESHNGE_HANDLER_NAME = @"hinadataNativeTracker";

NSSet* hinadata_reserved_properties() {
    return [NSSet setWithObjects:@"date", @"datetime", @"account_id", @"event", @"events", @"first_id", @"id", @"original_id", @"attr", @"second_id", @"time", @"user_id", @"users", nil];
}

BOOL hinadata_is_same_queue(dispatch_queue_t queue) {
    return strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0;
}

void hinadata_dispatch_safe_sync(dispatch_queue_t queue,DISPATCH_NOESCAPE dispatch_block_t block) {
    if ((dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL)) == dispatch_queue_get_label(queue)) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}

#pragma mark - Localization
NSString* hinadata_localized_string(NSString* key, NSString* value) {
    static NSBundle *languageBundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 获取语言资源的 Bundle
        NSBundle *hinaBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[HinaDataSDK class]] pathForResource:@"HinaDataSDK" ofType:@"bundle"]];
        NSString *path = [hinaBundle pathForResource:@"zh-Hans" ofType:@"lproj"];
        if (path) {
            languageBundle = [NSBundle bundleWithPath:path];
        }
    });
    
    NSString *result = value;
    if (languageBundle) {
        result = [languageBundle localizedStringForKey:key value:value table:nil];
    }
    return result;
}

#pragma mark - SF related notifications
NSNotificationName const HN_TRACK_EVENT_NOTIFICATION = @"HinaDataTrackEventNotification";
NSNotificationName const HN_TRACK_LOGIN_NOTIFICATION = @"HinaDataTrackLoginNotification";
NSNotificationName const HN_TRACK_LOGOUT_NOTIFICATION = @"HinaDataTrackLogoutNotification";
NSNotificationName const HN_TRACK_IDENTIFY_NOTIFICATION = @"HinaDataTrackIdentifyNotification";
NSNotificationName const HN_TRACK_RESETANONYMOUSID_NOTIFICATION = @"HinaDataTrackResetAnonymousIdNotification";
NSNotificationName const HN_TRACK_EVENT_H5_NOTIFICATION = @"HinaDataTrackEventFromH5Notification";

#pragma mark - ABTest related notifications
NSNotificationName const HN_H5_BRIDGE_NOTIFICATION = @"HinaDataRegisterJavaScriptBridgeNotification";

NSNotificationName const HN_H5_MESHNGE_NOTIFICATION = @"HinaDataMessageFromH5Notification";

#pragma mark - other
// 远程配置更新
NSNotificationName const HN_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION = @"cn.hinadata.HN_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION";

// 接收 App 内嵌 H5 可视化相关页面元素信息
NSNotificationName const kHNVisualizedMessageFromH5Notification = @"HinaDataVisualizedMessageFromH5Notification";

//page leave
NSString * const kHNEventDurationProperty = @"event_duration";
NSString * const kHNEventNameAppPageLeave = @"H_AppPageLeave";

//event name、property key、value max length
NSInteger kHNEventNameMaxLength = 100;
NSInteger kHNPropertyValueMaxLength = 1024;

#pragma mark - HN Visualized
/// 埋点校验中，H_WebClick 匹配可视化全埋点的事件名（集合）
NSString * const kHNWebVisualEventName = @"hinadata_web_visual_eventName";

/// App 内嵌 H5 的 Web 事件，属性配置中，需要 App 采集的属性
NSString * const kHNAppVisualProperties = @"hinadata_app_visual_properties";

/// App 内嵌 H5 的 Native 事件，属性配置中，需要 web 采集的属性
NSString * const kHNWebVisualProperties = @"hinadata_js_visual_properties";

HNLimitKey const HNLimitKeyIDFA = @"HNLimitKeyIDFA";
HNLimitKey const HNLimitKeyIDFV = @"HNLimitKeyIDFV";
HNLimitKey const HNLimitKeyCarrier = @"HNLimitKeyCarrier";


/// is instant event
NSString * const kHNInstantEventKey = @"is_instant_event";
