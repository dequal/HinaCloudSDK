//
// HNEventIdentifier.m
// HinaDataSDK
//
// Created by hina on 2022/3/23.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNEventIdentifier.h"
#import "UIViewController+HNAutoTrack.h"
#import "HNConstants+Private.h"

@implementation HNEventIdentifier

- (instancetype)initWithEventInfo:(NSDictionary *)eventInfo {
    NSDictionary *dic = [HNEventIdentifier eventIdentifierDicWithEventInfo:eventInfo];
    self = [super initWithDictionary:dic];
    if (self) {
        _eventName = eventInfo[@"event"];
        _properties = [eventInfo[kHNEventProperties] mutableCopy];
    }
    return self;
}

+ (NSDictionary *)eventIdentifierDicWithEventInfo:(NSDictionary *)eventInfo {
    NSMutableDictionary *eventInfoDic = [NSMutableDictionary dictionary];
    eventInfoDic[@"element_path"] = eventInfo[kHNEventProperties][kHNEventPropertyElementPath];
    eventInfoDic[@"element_position"] = eventInfo[kHNEventProperties][kHNEventPropertyElementPosition];
    eventInfoDic[@"element_content"] = eventInfo[kHNEventProperties][kHNEventPropertyElementContent];
    eventInfoDic[@"screen_name"] = eventInfo[kHNEventProperties][kHNEventPropertyScreenName];
    return eventInfoDic;
}
@end
