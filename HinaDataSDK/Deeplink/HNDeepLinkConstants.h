//
// HNDeepLinkConstants.h
// HinaDataSDK
//
// Created by hina on 2022/12/10.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

#pragma mark - Event Name
extern NSString *const kHNAppDeepLinkLaunchEvent;
extern NSString *const kHNDeepLinkMatchedResultEvent;
extern NSString *const kHNDeferredDeepLinkJumpEvent;

#pragma mark - Other
extern NSString *const kHNDeepLinkLatestChannelsFileName;
extern NSString *const kHNDeferredDeepLinkStatus;

#pragma mark - Event Property
extern NSString *const kHNEventPropertyDeepLinkURL;
extern NSString *const kHNEventPropertyDeepLinkOptions;
extern NSString *const kHNEventPropertyDeepLinkFailReason;
extern NSString *const kHNEventPropertyDuration;
extern NSString *const kHNEventPropertyADMatchType;
extern NSString *const kHNEventPropertyADDeviceInfo;
extern NSString *const kHNEventPropertyADChannel;
extern NSString *const kHNEventPropertyADSLinkID;

#pragma mark - Request Property
extern NSString *const kHNRequestPropertyUserAgent;

extern NSString *const kHNRequestPropertyIDs;
extern NSString *const kHNRequestPropertyUA;
extern NSString *const kHNRequestPropertyOS;
extern NSString *const kHNRequestPropertyOSVersion;
extern NSString *const kHNRequestPropertyModel;
extern NSString *const kHNRequestPropertyNetwork;
extern NSString *const kHNRequestPropertyTimestamp;
extern NSString *const kHNRequestPropertyAppID;
extern NSString *const kHNRequestPropertyAppVersion;
extern NSString *const kHNRequestPropertyAppParameter;
extern NSString *const kHNRequestPropertyProject;

#pragma mark - Response Property

extern NSString *const kHNResponsePropertySLinkID;

extern NSString *const kHNResponsePropertyCode;
extern NSString *const kHNResponsePropertyErrorMessage;
extern NSString *const kHNResponsePropertyErrorMsg;
extern NSString *const kHNResponsePropertyMessage;

// DeepLink
extern NSString *const kHNResponsePropertyParams;
extern NSString *const kHNResponsePropertyChannelParams;

// Deferred DeepLink
extern NSString *const kHNResponsePropertyParameter;
extern NSString *const kHNResponsePropertyADChannel;

NSSet* hinadata_preset_channel_keys(void);

//dynamic slink related message

//dynamic slink related code
extern NSInteger kHNDynamicSlinkStatusCodeSuccess;
extern NSInteger kHNDynamicSlinkStatusCodeLessParams;
extern NSInteger kHNDynamicSlinkStatusCodeNoNetwork;
extern NSInteger kHNDynamicSlinkStatusCodeoNoDomain;
extern NSInteger kHNDynamicSlinkStatusCodeResponseError;

//dynamic slink event name and properties
extern NSString *const kHNDynamicSlinkEventName;
extern NSString *const kHNDynamicSlinkEventPropertyChannelType;
extern NSString *const kHNDynamicSlinkEventPropertyChannelName;
extern NSString *const kHNDynamicSlinkEventPropertySource;
extern NSString *const kHNDynamicSlinkEventPropertyData;
extern NSString *const kHNDynamicSlinkEventPropertyShortURL;
extern NSString *const kHNDynamicSlinkEventPropertyStatus;
extern NSString *const kHNDynamicSlinkEventPropertyMessage;
extern NSString *const kHNDynamicSlinkEventPropertyID;
extern NSString *const kHNDynamicSlinkEventPropertyTemplateID;
extern NSString *const kHNDynamicSlinkEventPropertyType;
extern NSString *const kHNDynamicSlinkEventPropertyTypeDynamic;
extern NSString *const kHNDynamicSlinkEventPropertyCustomParams;

//dynamic slink API path
extern NSString *const kHNDynamicSlinkAPIPath;

//dynamic slink API params
extern NSString *const kHNDynamicSlinkParamProject;
extern NSString *const kHNDynamicSlinkParamTemplateID;
extern NSString *const kHNDynamicSlinkParamType;
extern NSString *const kHNDynamicSlinkParamName;
extern NSString *const kHNDynamicSlinkParamChannelType;
extern NSString *const kHNDynamicSlinkParamChannelName;
extern NSString *const kHNDynamicSlinkParamFixedUTM;
extern NSString *const kHNDynamicSlinkParamUTMSource;
extern NSString *const kHNDynamicSlinkParamUTMCampaign;
extern NSString *const kHNDynamicSlinkParamUTMMedium;
extern NSString *const kHNDynamicSlinkParamUTMTerm;
extern NSString *const kHNDynamicSlinkParamUTMContent;
extern NSString *const kHNDynamicSlinkParamCustom;
extern NSString *const kHNDynamicSlinkParamRoute;
extern NSString *const kHNDynamicSlinkParamURIScheme;
extern NSString *const kHNDynamicSlinkParamLandingPageType;
extern NSString *const kHNDynamicSlinkParamLandingPage;
extern NSString *const kHNDynamicSlinkParamJumpAddress;
extern NSString *const kHNDynamicSlinkParamSystemParams;

//slink response key
extern NSString *const kHNDynamicSlinkResponseKeyCustomParams;
