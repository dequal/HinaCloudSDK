//
// HNBaseEventObject.m
// HinaDataSDK
//
// Created by hina on 2022/4/13.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNBaseEventObject.h"
#import "HNConstants+Private.h"
#import "HNLog.h"

@implementation HNBaseEventObject

- (instancetype)init {
    self = [super init];
    if (self) {
        _type = HNEventTypeTrack;
        _lib = [[HNEventLibObject alloc] init];
        _time = [[NSDate date] timeIntervalSince1970] * 1000;
        _trackId = @(arc4random());
        _properties = [NSMutableDictionary dictionary];
        _currentSystemUpTime = NSProcessInfo.processInfo.systemUptime * 1000;
        
        _ignoreRemoteConfig = NO;
        _hybridH5 = NO;
        _isInstantEvent = NO;
    }
    return self;
}

- (instancetype)initWithH5Event:(NSDictionary *)event {
    self = [super init];
    if (self) {
        NSString *type = event[kHNEventType];
        _type = [HNBaseEventObject eventTypeWithType:type];
        _lib = [[HNEventLibObject alloc] initWithH5Lib:event[kHNEventLib]];
        _time = [[NSDate date] timeIntervalSince1970] * 1000;
        _trackId = @(arc4random());
        _currentSystemUpTime = NSProcessInfo.processInfo.systemUptime * 1000;
        
        _ignoreRemoteConfig = NO;
        
        _hybridH5 = YES;
        
        _eventId = event[kHNEventName];
        _loginId = event[kHNEventLoginId];
        _anonymousId = event[kHNEvent_distinct_id];
        _distinctId = event[kHNEventDistinctId];
        _originalId = event[kHNEventOriginalId];
        _identities = event[kHNEventIdentities];
        NSMutableDictionary *properties = [event[kHNEventProperties] mutableCopy];
        [properties removeObjectForKey:@"_nocache"];
        
        _project = properties[kHNEventProject];
        _token = properties[kHNEventToken];
        
        id timeNumber = properties[kHNEventCommonOptionalPropertyTime];
        if (timeNumber) {     //包含 $time
            NSNumber *customTime = nil;
            if ([timeNumber isKindOfClass:[NSDate class]]) {
                customTime = @([(NSDate *)timeNumber timeIntervalSince1970] * 1000);
            } else if ([timeNumber isKindOfClass:[NSNumber class]]) {
                customTime = timeNumber;
            }
            
            if (!customTime) {
                HNLogError(@"H5 $time '%@' invalid，Please check the value", timeNumber);
            } else if ([customTime compare:@(kHNEventCommonOptionalPropertyTimeInt)] == NSOrderedAscending) {
                HNLogError(@"H5 $time error %@，Please check the value", timeNumber);
            } else {
                _time = [customTime unsignedLongLongValue];
            }
        }
        
        [properties removeObjectsForKeys:@[@"_nocache", @"server_url", kHNAppVisualProperties, kHNEventProject, kHNEventToken, kHNEventCommonOptionalPropertyTime]];
        _properties = properties;
        NSNumber *isInstantEvent = event[kHNInstantEventKey];
        if ([isInstantEvent isKindOfClass:[NSNumber class]]) {
            _isInstantEvent = [isInstantEvent boolValue];
        }
    }
    return self;
}

- (NSString *)event {
    if (![self.eventId isKindOfClass:[NSString class]]) {
        return nil;
    }
    if (![self.eventId hasSuffix:kHNEventIdSuffix]) {
        return self.eventId;
    }
    //eventId 结构为 {eventName}_D3AC265B_3CC2_4C45_B8F0_3E05A83A9DAE_HNTimer，新增后缀长度为 44
    if (self.eventId.length < 45) {
        return nil;
    }
    NSString *eventName = [self.eventId substringToIndex:(self.eventId.length - 1) - 44];
    return eventName;
}

- (BOOL)isSignUp {
    return NO;
}

- (void)validateEventWithError:(NSError **)error {
}

- (NSMutableDictionary *)jsonObject {
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    eventInfo[kHNEventProperties] = self.properties;
    
    //    eventInfo[kHNEventDistinctId] = self.distinctId;
    // 修改了account_id的逻辑 未登录为空字符串
    if (self.loginId) {
        eventInfo[kHNEventDistinctId] = self.distinctId;
    } else {
        eventInfo[kHNEventDistinctId] = @"";
    }
    
    eventInfo[kHNEventLoginId] = self.loginId;
    eventInfo[kHNEvent_distinct_id] = self.anonymousId;
    eventInfo[kHNEventType] = [HNBaseEventObject typeWithEventType:self.type];
    eventInfo[kHNEventTime] = @(self.time);
    eventInfo[kHNEventLib] = [self.lib jsonObject];
    eventInfo[kHNEventTrackId] = self.trackId;
    eventInfo[kHNEventName] = self.event;
    eventInfo[kHNEventProject] = self.project;
    eventInfo[kHNEventToken] = self.token;
    eventInfo[kHNEventIdentities] = self.identities;
    // App 内嵌 H5 事件标记
    eventInfo[kHNEventHybridH5] = self.hybridH5 ? @(self.hybridH5) : nil;
    return eventInfo;
}

- (id)hinadata_validKey:(NSString *)key value:(id)value error:(NSError *__autoreleasing  _Nullable *)error {
    if (![key conformsToProtocol:@protocol(HNPropertyKeyProtocol)]) {
        *error = HNPropertyError(10004, @"Property Key: %@ must be NSString", key);
        return nil;
    }
    
    // key 校验
    [(id <HNPropertyKeyProtocol>)key hinadata_isValidPropertyKeyWithError:error];
    if (*error && (*error).code != HNValidatorErrorOverflow) {
        return nil;
    }
    
    if (![value conformsToProtocol:@protocol(HNPropertyValueProtocol)]) {
        *error = HNPropertyError(10005, @"%@ property values must be NSString, NSNumber, NSSet, NSArray or NSDate. got: %@ %@", self, [value class], value);
        return nil;
    }
    
    // value 转换
    return [(id <HNPropertyValueProtocol>)value hinadata_propertyValueWithKey:key error:error];
}

+ (HNEventType)eventTypeWithType:(NSString *)type {
    if ([type isEqualToString:kHNEventTypeTrack]) {
        return HNEventTypeTrack;
    }
    if ([type isEqualToString:kHNEventTypeSignup]) {
        return HNEventTypeSignup;
    }
    if ([type isEqualToString:kHNEventTypeBind]) {
        return HNEventTypeBind;
    }
    if ([type isEqualToString:kHNEventTypeUnbind]) {
        return HNEventTypeUnbind;
    }
    if ([type isEqualToString:kHNProfileSet]) {
        return HNEventTypeProfileSet;
    }
    if ([type isEqualToString:kHNProfileSetOnce]) {
        return HNEventTypeProfileSetOnce;
    }
    if ([type isEqualToString:kHNProfileUnset]) {
        return HNEventTypeProfileUnset;
    }
    if ([type isEqualToString:kHNProfileDelete]) {
        return HNEventTypeProfileDelete;
    }
    if ([type isEqualToString:kHNProfileAppend]) {
        return HNEventTypeProfileAppend;
    }
    if ([type isEqualToString:kHNProfileIncrement]) {
        return HNEventTypeIncrement;
    }
    if ([type isEqualToString:kHNEventItemSet]) {
        return HNEventTypeItemSet;
    }
    if ([type isEqualToString:kHNEventItemDelete]) {
        return HNEventTypeItemDelete;
    }
    return HNEventTypeDefault;
}

+ (NSString *)typeWithEventType:(HNEventType)type {
    if (type & HNEventTypeTrack) {
        return kHNEventTypeTrack;
    }
    if (type & HNEventTypeSignup) {
        return kHNEventTypeSignup;
    }
    if (type & HNEventTypeProfileSet) {
        return kHNProfileSet;
    }
    if (type & HNEventTypeProfileSetOnce) {
        return kHNProfileSetOnce;
    }
    if (type & HNEventTypeProfileUnset) {
        return kHNProfileUnset;
    }
    if (type & HNEventTypeProfileDelete) {
        return kHNProfileDelete;
    }
    if (type & HNEventTypeProfileAppend) {
        return kHNProfileAppend;
    }
    if (type & HNEventTypeIncrement) {
        return kHNProfileIncrement;
    }
    if (type & HNEventTypeItemSet) {
        return kHNEventItemSet;
    }
    if (type & HNEventTypeItemDelete) {
        return kHNEventItemDelete;
    }
    if (type & HNEventTypeBind) {
        return kHNEventTypeBind;
    }
    if (type & HNEventTypeUnbind) {
        return kHNEventTypeUnbind;
    }
    
    return nil;
}

@end
