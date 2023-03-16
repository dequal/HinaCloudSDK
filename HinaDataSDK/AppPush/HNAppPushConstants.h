//
// HNAppPushConstants.h
// HinaDataSDK
//
// Created by hina on 2022/1/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

//AppPush Notification related
extern NSString * const kHNEventNameNotificationClick;
extern NSString * const kHNEventPropertyNotificationTitle;
extern NSString * const kHNEventPropertyNotificationContent;
extern NSString * const kHNEventPropertyNotificationServiceName;
extern NSString * const kHNEventPropertyNotificationChannel;
extern NSString * const kHNEventPropertyNotificationServiceNameLocal;
extern NSString * const kHNEventPropertyNotificationServiceNameJPUSH;
extern NSString * const kHNEventPropertyNotificationServiceNameGeTui;
extern NSString * const kHNEventPropertyNotificationChannelApple;

//identifier for third part push service
extern NSString * const kHNPushServiceKeyJPUSH;
extern NSString * const kHNPushServiceKeyGeTui;
extern NSString * const kHNPushServiceKeySF;

//APNS related key
extern NSString * const kHNPushAppleUserInfoKeyAps;
extern NSString * const kHNPushAppleUserInfoKeyAlert;
extern NSString * const kHNPushAppleUserInfoKeyTitle;
extern NSString * const kHNPushAppleUserInfoKeyBody;

//sf_data related properties
extern NSString * const kSFMessageTitle;
extern NSString * const kSFPlanStrategyID;
extern NSString * const kSFChannelCategory;
extern NSString * const kSFAudienceID;
extern NSString * const kSFChannelID;
extern NSString * const kSFLinkUrl;
extern NSString * const kSFPlanType;
extern NSString * const kSFChannelServiceName;
extern NSString * const kSFMessageID;
extern NSString * const kSFPlanID;
extern NSString * const kSFStrategyUnitID;
extern NSString * const kSFEnterPlanTime;
extern NSString * const kSFMessageContent;
