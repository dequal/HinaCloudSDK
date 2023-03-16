//
// HNDeepLinkConstants.m
// HinaDataSDK
//
// Created by hina on 2022/12/10.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>

#pragma mark - Event Name

NSString *const kHNAppDeepLinkLaunchEvent = @"H_AppDeeplinkLaunch";
NSString *const kHNDeepLinkMatchedResultEvent = @"H_AppDeeplinkMatchedResult";
NSString *const kHNDeferredDeepLinkJumpEvent = @"H_AdAppDeferredDeepLinkJump";

#pragma mark - Other
NSString *const kHNDeepLinkLatestChannelsFileName = @"latest_utms";
NSString *const kHNDeferredDeepLinkStatus = @"RequestDeferredDeepLinkStatus";

#pragma mark - Event Property
NSString *const kHNEventPropertyDeepLinkURL = @"H_deeplink_url";
NSString *const kHNEventPropertyDeepLinkOptions = @"H_deeplink_options";
NSString *const kHNEventPropertyDeepLinkFailReason = @"H_deeplink_match_fail_reason";
NSString *const kHNEventPropertyDuration = @"H_event_duration";
NSString *const kHNEventPropertyADMatchType = @"H_ad_app_match_type";
NSString *const kHNEventPropertyADDeviceInfo = @"H_ad_device_info";
NSString *const kHNEventPropertyADChannel= @"H_ad_deeplink_channel_info";
NSString *const kHNEventPropertyADSLinkID = @"H_ad_slink_id";

#pragma mark - Request Property
NSString *const kHNRequestPropertyUserAgent = @"H_user_agent";

NSString *const kHNRequestPropertyIDs = @"ids";
NSString *const kHNRequestPropertyUA = @"ua";
NSString *const kHNRequestPropertyOS = @"os";
NSString *const kHNRequestPropertyOSVersion = @"os_version";
NSString *const kHNRequestPropertyModel = @"model";
NSString *const kHNRequestPropertyNetwork = @"network";
NSString *const kHNRequestPropertyTimestamp = @"timestamp";
NSString *const kHNRequestPropertyAppID = @"app_id";
NSString *const kHNRequestPropertyAppVersion = @"app_version";
NSString *const kHNRequestPropertyAppParameter = @"app_parameter";
NSString *const kHNRequestPropertyProject = @"project";

#pragma mark - Response Property

NSString *const kHNResponsePropertyCode = @"code";
NSString *const kHNResponsePropertyErrorMessage = @"errorMsg";
NSString *const kHNResponsePropertyErrorMsg = @"error_msg";
NSString *const kHNResponsePropertyMessage = @"msg";

NSString *const kHNResponsePropertySLinkID = @"ad_slink_id";

// DeepLink
NSString *const kHNResponsePropertyParams = @"page_params";
NSString *const kHNResponsePropertyChannelParams = @"channel_params";

// Deferred DeepLink
NSString *const kHNResponsePropertyParameter = @"parameter";
NSString *const kHNResponsePropertyADChannel = @"ad_channel";


NSSet* hinadata_preset_channel_keys(void) {
    return [NSSet setWithObjects:@"utm_campaign", @"utm_content", @"utm_medium", @"utm_source", @"utm_term", nil];
}

//dynamic slink related code
NSInteger kHNDynamicSlinkStatusCodeSuccess= 0;
NSInteger kHNDynamicSlinkStatusCodeLessParams = 10001;
NSInteger kHNDynamicSlinkStatusCodeNoNetwork = 10002;
NSInteger kHNDynamicSlinkStatusCodeoNoDomain = 10003;
NSInteger kHNDynamicSlinkStatusCodeResponseError = 10004;

//dynamic slink event name and properties
NSString *const kHNDynamicSlinkEventName = @"H_AdDynamicSlinkCreate";
NSString *const kHNDynamicSlinkEventPropertyChannelType = @"H_ad_dynamic_slink_channel_type";
NSString *const kHNDynamicSlinkEventPropertyChannelName = @"H_ad_dynamic_slink_channel_name";
NSString *const kHNDynamicSlinkEventPropertySource = @"H_ad_dynamic_slink_source";
NSString *const kHNDynamicSlinkEventPropertyData = @"H_ad_dynamic_slink_data";
NSString *const kHNDynamicSlinkEventPropertyShortURL = @"H_ad_dynamic_slink_short_url";
NSString *const kHNDynamicSlinkEventPropertyStatus = @"H_ad_dynamic_slink_status";
NSString *const kHNDynamicSlinkEventPropertyMessage = @"H_ad_dynamic_slink_msg";
NSString *const kHNDynamicSlinkEventPropertyID = @"H_ad_slink_id";
NSString *const kHNDynamicSlinkEventPropertyTemplateID = @"H_ad_slink_template_id";
NSString *const kHNDynamicSlinkEventPropertyType = @"H_ad_slink_type";
NSString *const kHNDynamicSlinkEventPropertyTypeDynamic = @"dynamic";
NSString *const kHNDynamicSlinkEventPropertyCustomParams = @"H_sat_slink_custom_params";

//dynamic slink API path
NSString *const kHNDynamicSlinkAPIPath = @"slink/dynamic/links";

//dynamic slink API params
NSString *const kHNDynamicSlinkParamProject = @"project_name";
NSString *const kHNDynamicSlinkParamTemplateID = @"slink_template_id";
NSString *const kHNDynamicSlinkParamType = @"slink_type";
NSString *const kHNDynamicSlinkParamName = @"name";
NSString *const kHNDynamicSlinkParamChannelType = @"channel_type";
NSString *const kHNDynamicSlinkParamChannelName = @"channel_name";
NSString *const kHNDynamicSlinkParamFixedUTM = @"fixed_param";
NSString *const kHNDynamicSlinkParamUTMSource = @"channel_utm_source";
NSString *const kHNDynamicSlinkParamUTMCampaign = @"channel_utm_campaign";
NSString *const kHNDynamicSlinkParamUTMMedium = @"channel_utm_medium";
NSString *const kHNDynamicSlinkParamUTMTerm = @"channel_utm_term";
NSString *const kHNDynamicSlinkParamUTMContent = @"channel_utm_content";
NSString *const kHNDynamicSlinkParamCustom = @"custom_param";
NSString *const kHNDynamicSlinkParamRoute = @"route_param";
NSString *const kHNDynamicSlinkParamURIScheme = @"uri_scheme_suffix";
NSString *const kHNDynamicSlinkParamLandingPageType = @"landing_page_type";
NSString *const kHNDynamicSlinkParamLandingPage = @"other_landing_page_map";
NSString *const kHNDynamicSlinkParamJumpAddress = @"jump_address";
NSString *const kHNDynamicSlinkParamSystemParams = @"system_param";

//slink response key
NSString *const kHNDynamicSlinkResponseKeyCustomParams = @"custom_params";
