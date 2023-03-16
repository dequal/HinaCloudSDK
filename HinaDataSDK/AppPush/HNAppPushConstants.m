//
// HNAppPushConstants.m
// HinaDataSDK
//
// Created by hina on 2022/1/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAppPushConstants.h"

//AppPush Notification related
NSString * const kHNEventNameNotificationClick = @"H_AppPushClick";
NSString * const kHNEventPropertyNotificationTitle = @"H_app_push_msg_title";
NSString * const kHNEventPropertyNotificationContent = @"H_app_push_msg_content";
NSString * const kHNEventPropertyNotificationServiceName = @"H_app_push_service_name";
NSString * const kHNEventPropertyNotificationChannel = @"H_app_push_channel";
NSString * const kHNEventPropertyNotificationServiceNameLocal = @"Local";
NSString * const kHNEventPropertyNotificationServiceNameJPUSH = @"JPush";
NSString * const kHNEventPropertyNotificationServiceNameGeTui = @"GeTui";
NSString * const kHNEventPropertyNotificationChannelApple = @"Apple";

//identifier for third part push service
NSString * const kHNPushServiceKeyJPUSH = @"_j_business";
NSString * const kHNPushServiceKeyGeTui = @"_ge_";
NSString * const kHNPushServiceKeySF = @"sf_data";

//APNS related key
NSString * const kHNPushAppleUserInfoKeyAps = @"aps";
NSString * const kHNPushAppleUserInfoKeyAlert = @"alert";
NSString * const kHNPushAppleUserInfoKeyTitle = @"title";
NSString * const kHNPushAppleUserInfoKeyBody = @"body";

//sf_data related properties
NSString * const kSFMessageTitle = @"H_sf_msg_title";
NSString * const kSFPlanStrategyID = @"H_sf_plan_strategy_id";
NSString * const kSFChannelCategory = @"H_sf_channel_category";
NSString * const kSFAudienceID = @"H_sf_audience_id";
NSString * const kSFChannelID = @"H_sf_channel_id";
NSString * const kSFLinkUrl = @"H_sf_link_url";
NSString * const kSFPlanType = @"H_sf_plan_type";
NSString * const kSFChannelServiceName = @"H_sf_channel_service_name";
NSString * const kSFMessageID = @"H_sf_msg_id";
NSString * const kSFPlanID = @"H_sf_plan_id";
NSString * const kSFStrategyUnitID = @"H_sf_strategy_unit_id";
NSString * const kSFEnterPlanTime = @"H_sf_enter_plan_time";
NSString * const kSFMessageContent = @"H_sf_msg_content";
