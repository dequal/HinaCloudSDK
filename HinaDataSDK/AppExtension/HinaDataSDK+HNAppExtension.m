//
// HinaDataSDK+HNAppExtension.m
// HinaDataSDK
//
// Created by hina on 2022/5/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HinaDataSDK+HNAppExtension.h"
#import "HNLog.h"
#import "HNAppExtensionDataManager.h"
#import "HNConstants+Private.h"

@implementation HinaDataSDK (HNAppExtension)

- (void)trackEventFromExtensionWithGroupIdentifier:(NSString *)groupIdentifier completion:(void (^)(NSString *groupIdentifier, NSArray *events)) completion {
    @try {
        if (groupIdentifier == nil || [groupIdentifier isEqualToString:@""]) {
            return;
        }
        NSArray *eventArray = [[HNAppExtensionDataManager sharedInstance] readAllEventsWithGroupIdentifier:groupIdentifier];
        if (eventArray) {
            for (NSDictionary *dict in eventArray) {
                NSString *event = [dict[kHNEventName] copy];
                NSDictionary *properties = [dict[kHNEventProperties] copy];
                [[HinaDataSDK sharedInstance] track:event withProperties:properties];
            }
            [[HNAppExtensionDataManager sharedInstance] deleteEventsWithGroupIdentifier:groupIdentifier];
            if (completion) {
                completion(groupIdentifier, eventArray);
            }
        }
    } @catch (NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
}

@end
