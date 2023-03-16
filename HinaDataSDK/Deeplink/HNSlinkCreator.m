//
// HNSlinkCreator.m
// HinaDataSDK
//
// Created by hina on 2022/7/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNSlinkCreator.h"
#import "HNReachability.h"
#import "HNJSONUtil.h"
#import "HinaDataSDK+Private.h"
#import "HinaDataSDK.h"
#import "HNLog.h"
#import "HNDeepLinkConstants.h"
#import "HNConstants+Private.h"


@implementation HNTUTMProperties

@end

@interface HNSlinkResponse ()

@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy, nullable) NSString *slink;
@property (nonatomic, copy) NSString *commonRedirectURI;

- (instancetype)initWithSlink:(NSString *)slink slinkID:(NSString *)slinkID message:(NSString *)message statusCode:(NSInteger)statusCode commonRedirectURI:(NSString *)commonRedirectURI;

@end

@implementation HNSlinkResponse

- (instancetype)initWithSlink:(NSString *)slink slinkID:(NSString *)slinkID message:(NSString *)message statusCode:(NSInteger)statusCode commonRedirectURI:(NSString *)commonRedirectURI {
    self = [super init];
    if (self) {
        _slink = slink;
        _slinkID = slinkID;
        _message = message.length > 200 ? [message substringToIndex:200] : message;
        _statusCode = statusCode;
        _commonRedirectURI = commonRedirectURI;
    }
    return self;
}

@end

@interface HNSlinkCreator ()

//required params
@property (nonatomic, copy) NSString *templateID;
@property (nonatomic, copy) NSString *channelName;
@property (nonatomic, copy) NSString *commonRedirectURI;
@property (nonatomic, copy) NSString *accessToken;

@property (nonatomic, copy) NSString *channelType;
@property (nonatomic, copy) NSString *projectName;


@end

@implementation HNSlinkCreator

- (instancetype)initWithTemplateID:(NSString *)templateID channelName:(NSString *)channelName commonRedirectURI:(NSString *)commonRedirectURI accessToken:(NSString *)accessToken {
    self = [super init];
    if (self) {
        _templateID = templateID;
        _channelName = channelName;
        _commonRedirectURI = commonRedirectURI;
        _accessToken = accessToken;
        _landingPageType = HNTLandingPageTypeUndefined;
        _channelType = @"app_share";
    }
    return self;
}

- (void)createSlinkWithCompletion:(void (^)(HNSlinkResponse * _Nonnull))completion {
    //check network reachable
    if (![HNReachability sharedInstance].reachable) {
        HNSlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:HNLocalizedString(@"HNDynamicSlinkMessageNoNetwork") statusCode:kHNDynamicSlinkStatusCodeNoNetwork];
        completion(response);
        return;
    }
    //check custom domain
    NSString *customADChannelURL = HinaDataSDK.sdkInstance.configOptions.customADChannelURL;
    if (![customADChannelURL isKindOfClass:[NSString class]] || customADChannelURL.length < 1) {
        HNSlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:HNLocalizedString(@"HNDynamicSlinkMessageNoDomain") statusCode:kHNDynamicSlinkStatusCodeoNoDomain];
        completion(response);
        return;
    }
    //check access token
    if (![self.accessToken isKindOfClass:[NSString class]] || self.accessToken.length < 1) {
        HNSlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:HNLocalizedString(@"HNDynamicSlinkMessageNoAccessToken") statusCode:kHNDynamicSlinkStatusCodeLessParams];
        completion(response);
        return;
    }
    //check project
    NSString *project = HinaDataSDK.sdkInstance.network.project;
    if (![project isKindOfClass:[NSString class]] || project.length < 1) {
        HNSlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:HNLocalizedString(@"HNDynamicSlinkMessageNoProject") statusCode:kHNDynamicSlinkStatusCodeLessParams];
        completion(response);
        return;
    }
    //check templateID
    if (![self.templateID isKindOfClass:[NSString class]] || self.templateID.length < 1) {
        HNSlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:HNLocalizedString(@"HNDynamicSlinkMessageNoTemplateID") statusCode:kHNDynamicSlinkStatusCodeLessParams];
        completion(response);
        return;
    }
    //check channel name
    if (![self.channelName isKindOfClass:[NSString class]] || self.channelName.length < 1) {
        HNSlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:HNLocalizedString(@"HNDynamicSlinkMessageNoChannelName") statusCode:kHNDynamicSlinkStatusCodeLessParams];
        completion(response);
        return;
    }
    //check commonRedirectURI
    if (![self.commonRedirectURI isKindOfClass:[NSString class]] || self.commonRedirectURI.length < 1) {
        HNSlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:HNLocalizedString(@"HNDynamicSlinkMessageNoRedirectURI") statusCode:kHNDynamicSlinkStatusCodeLessParams];
        completion(response);
        return;
    }

    //request dynamic slink
    NSDictionary *params = [self buildSlinkParams];
    NSURLRequest *request = [self buildSlinkRequestWithParams:params];
    NSURLSessionDataTask *task = [[HNHTTPSession sharedInstance] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable httpResponse, NSError * _Nullable error) {
        if (!httpResponse) {
            HNSlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:error.localizedDescription statusCode:error.code];
            completion(response);
            return;
        }
        NSInteger statusCode = httpResponse.statusCode;
        NSString *message = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
        NSDictionary *result = [HNJSONUtil JSONObjectWithData:data];
        if (![result isKindOfClass:[NSDictionary class]]) {
            HNSlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:message statusCode:statusCode];
            completion(response);
            return;
        }
        message = result[@"msg"] ? : message;
        if (httpResponse.statusCode == 200) {
            if (!result[@"code"]) {
                HNSlinkResponse *response = [self responseWithSlink:nil slinkID:nil message:HNLocalizedString(@"HNDynamicSlinkMessageResponseError") statusCode:kHNDynamicSlinkStatusCodeResponseError];
                completion(response);
                return;
            }
            statusCode = [result[@"code"] respondsToSelector:@selector(integerValue)] ? [result[@"code"] integerValue] : statusCode;
            NSDictionary *slinkData = result[@"data"];
            NSString *slink = nil;
            NSString *slinkID = nil;
            if ([slinkData isKindOfClass:[NSDictionary class]]) {
                slink = slinkData[@"short_url"];
                slinkID = slinkData[@"slink_id"];
            }
            HNSlinkResponse *response = [self responseWithSlink:slink slinkID:slinkID message:message statusCode:statusCode];
            completion(response);
            return;
        }
        HNSlinkResponse *slinkResponse = [self responseWithSlink:nil slinkID:nil message:message statusCode:statusCode];
        completion(slinkResponse);
    }];
    [task resume];
}

- (HNSlinkResponse *)responseWithSlink:(NSString *)slink slinkID:(NSString *)slinkID message:(NSString *)message statusCode:(NSInteger)statusCode {
    HNSlinkResponse *response = [[HNSlinkResponse alloc] initWithSlink:slink slinkID:slinkID message:message statusCode:statusCode commonRedirectURI:self.commonRedirectURI];
    [self trackEventWithSlinkResponse:response];
    return response;
}

- (void)trackEventWithSlinkResponse:(HNSlinkResponse *)response {
    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    properties[kHNDynamicSlinkEventPropertyChannelType] = self.channelType;
    properties[kHNDynamicSlinkEventPropertyChannelName] = self.channelName ? : @"";
    properties[kHNDynamicSlinkEventPropertySource] = @"iOS";
    properties[kHNDynamicSlinkEventPropertyData] = @"";
    properties[kHNDynamicSlinkEventPropertyShortURL] = response.slink ? : @"";
    properties[kHNDynamicSlinkEventPropertyStatus] = @(response.statusCode);
    properties[kHNDynamicSlinkEventPropertyMessage] = response.message;
    properties[kHNDynamicSlinkEventPropertyID] = response.slinkID ? : @"";
    properties[kHNDynamicSlinkEventPropertyTemplateID] = self.templateID ? : @"";
    properties[kHNDynamicSlinkEventPropertyType] = kHNDynamicSlinkEventPropertyTypeDynamic;
    [[HinaDataSDK sharedInstance] track:kHNDynamicSlinkEventName withProperties:[properties copy]];
}

- (NSDictionary *)buildSlinkParams {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[kHNDynamicSlinkParamProject] = HinaDataSDK.sdkInstance.network.project;
    params[kHNDynamicSlinkParamTemplateID] = self.templateID;
    params[kHNDynamicSlinkParamChannelType] = self.channelType;
    params[kHNDynamicSlinkParamChannelName] = self.channelName;
    if (self.name) {
        params[kHNDynamicSlinkParamName] = self.name;
    }
    if (self.customParams) {
        params[kHNDynamicSlinkParamCustom] = self.customParams;
    }
    if (self.routeParam) {
        params[kHNDynamicSlinkParamRoute] = self.routeParam;
    }
    if (self.uriSchemeSuffix) {
        params[kHNDynamicSlinkParamURIScheme] = self.uriSchemeSuffix;
    }
    if (self.landingPageType == HNTLandingPageTypeIntelligence) {
        params[kHNDynamicSlinkParamLandingPageType] = @"intelligence";
    } else if (self.landingPageType == HNTLandingPageTypeOther) {
        params[kHNDynamicSlinkParamLandingPageType] = @"other";
    } else {
        HNLogInfo(@"Undefined Slink landing page type: %lu", self.landingPageType);
    }
    if (self.landingPage) {
        params[kHNDynamicSlinkParamLandingPage] = self.landingPage;
    }
    if (self.redirectURLOnOtherDevice) {
        params[kHNDynamicSlinkParamJumpAddress] = self.redirectURLOnOtherDevice;
    }
    if ([self.systemParams isKindOfClass:[NSDictionary class]]) {
        params[kHNDynamicSlinkParamSystemParams] = [self.systemParams copy];
    }
    if (!self.utmProperties) {
        return [params copy];
    }
    NSMutableDictionary *utmProperties = [NSMutableDictionary dictionary];
    if (self.utmProperties.source) {
        utmProperties[kHNDynamicSlinkParamUTMSource] = self.utmProperties.source;
    }
    if (self.utmProperties.campaign) {
        utmProperties[kHNDynamicSlinkParamUTMCampaign] = self.utmProperties.campaign;
    }
    if (self.utmProperties.medium) {
        utmProperties[kHNDynamicSlinkParamUTMMedium] = self.utmProperties.medium;
    }
    if (self.utmProperties.term) {
        utmProperties[kHNDynamicSlinkParamUTMTerm] = self.utmProperties.term;
    }
    if (self.utmProperties.content) {
        utmProperties[kHNDynamicSlinkParamUTMContent] = self.utmProperties.content;
    }
    params[kHNDynamicSlinkParamFixedUTM] = [utmProperties copy];

    return [params copy];
}

- (NSURLRequest *)buildSlinkRequestWithParams:(NSDictionary *)params {
    NSString *customADChannelURL = HinaDataSDK.sdkInstance.configOptions.customADChannelURL;
    if (![customADChannelURL isKindOfClass:[NSString class]]) {
        return nil;
    }
    NSURL *slinkBaseURL = [NSURL URLWithString:customADChannelURL];
    if (!slinkBaseURL) {
        return nil;
    }
    NSURL *slinkURL = [slinkBaseURL URLByAppendingPathComponent:kHNDynamicSlinkAPIPath];
    if (!slinkURL) {
        return nil;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:slinkURL];
    request.timeoutInterval = 30;
    request.HTTPBody = [HNJSONUtil dataWithJSONObject:params];
    [request setHTTPMethod:@"POST"];
    [request setValue:self.accessToken forHTTPHeaderField:@"token"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    return request;
}

@end
