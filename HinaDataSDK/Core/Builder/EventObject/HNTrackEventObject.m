//
// HNTrackEventObject.m
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNTrackEventObject.h"
#import "HNConstants+Private.h"
#import "HNValidator.h"
#import "HNLog.h"
#import "HinaDataSDK+Private.h"
#import "HNSessionProperty.h"

@implementation HNTrackEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super init];
    if (self) {
        self.eventId = eventId ? [NSString stringWithFormat:@"%@", eventId] : nil;
    }
    return self;
}

- (void)validateEventWithError:(NSError **)error {
    [HNValidator validKey:self.eventId error:error];
}

@end

@implementation HNSignUpEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = HNEventTypeSignup;
    }
    return self;
}

- (instancetype)initWithH5Event:(NSDictionary *)event {
    self = [super initWithH5Event:event];
    if (self) {
        self.type = HNEventTypeSignup;
    }
    return self;
}

- (NSMutableDictionary *)jsonObject {
    NSMutableDictionary *jsonObject = [super jsonObject];
    jsonObject[kHNEventOriginalId] = self.originalId;
    return jsonObject;
}

- (BOOL)isSignUp {
    return YES;
}

// H_SignUp 事件不添加该属性
- (void)addModuleProperties:(NSDictionary *)properties {
}

@end

@implementation HNCustomEventObject

@end

@implementation HNAutoTrackEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = HNEventTypeTrack;
        self.lib.method = kHNLibMethodAuto;
    }
    return self;
}

@end

@implementation HNPresetEventObject

@end

/// 绑定 ID 事件
@implementation HNBindEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = HNEventTypeBind;
    }
    return self;
}

- (instancetype)initWithH5Event:(NSDictionary *)event {
    self = [super initWithH5Event:event];
    if (self) {
        self.type = HNEventTypeBind;
    }
    return self;
}

@end

/// 解绑 ID 事件
@implementation HNUnbindEventObject

- (instancetype)initWithEventId:(NSString *)eventId {
    self = [super initWithEventId:eventId];
    if (self) {
        self.type = HNEventTypeUnbind;
    }
    return self;
}

- (instancetype)initWithH5Event:(NSDictionary *)event {
    self = [super initWithH5Event:event];
    if (self) {
        self.type = HNEventTypeUnbind;
    }
    return self;
}

@end
