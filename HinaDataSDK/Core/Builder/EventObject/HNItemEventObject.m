//
// HNItemEventObject.m
// HinaDataSDK
//
// Created by hina on 2022/11/3.
// Copyright © 2021 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNItemEventObject.h"
#import "HNConstants+Private.h"

static NSString * const kHNEventItemType = @"item_type";
static NSString * const kHNEventItemID = @"item_id";

@implementation HNItemEventObject

- (instancetype)initWithType:(NSString *)type itemType:(NSString *)itemType itemID:(NSString *)itemID {
    self = [super init];
    if (self) {
        self.type = [HNItemEventObject eventTypeWithType:type];
        _itemType = itemType;
        _itemID = itemID;
    }
    return self;
}

- (void)validateEventWithError:(NSError **)error {
    [HNValidator validKey:self.itemType error:error];
    if (*error && (*error).code != HNValidatorErrorOverflow) {
        self.itemType = nil;
    }

    if (![self.itemID isKindOfClass:[NSString class]]) {
        *error = HNPropertyError(HNValidatorErrorNotString, @"Item_id must be a string");
        self.itemID = nil;
        return;
    }
    if (self.itemID.length > kHNPropertyValueMaxLength) {
        *error = HNPropertyError(HNValidatorErrorOverflow, @"%@'s length is longer than %ld", self.itemID, kHNPropertyValueMaxLength);
        return;
    }
}

- (NSMutableDictionary *)jsonObject {
    NSMutableDictionary *eventInfo = [NSMutableDictionary dictionary];
    eventInfo[kHNEventProperties] = (self.type & HNEventTypeItemDelete) ? nil : self.properties;
    eventInfo[kHNEventItemType] = self.itemType;
    eventInfo[kHNEventItemID] = self.itemID;
    eventInfo[kHNEventType] = [HNBaseEventObject typeWithEventType:self.type];
    eventInfo[kHNEventTime] = @(self.time);
    eventInfo[kHNEventLib] = [self.lib jsonObject];
    eventInfo[kHNEventProject] = self.project;
    eventInfo[kHNEventToken] = self.token;
    return eventInfo;
}

@end
