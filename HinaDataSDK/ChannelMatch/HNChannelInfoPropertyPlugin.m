//
// HNChannelInfoPropertyPlugin.m
// HinaDataSDK
//
// Created by  hina on 2022/4/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNChannelInfoPropertyPlugin.h"
#import "HNPropertyPlugin+HNPrivate.h"
#import "HNConstants+Private.h"
#import "HNModuleManager.h"
#import "HNTrackEventObject.h"

@implementation HNChannelInfoPropertyPlugin

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    // 不支持 H5 打通事件
    // 开启 enableAutoAddChannelCallbackEvent 后，只有手动 track 事件包含渠道信息
    if ([filter hybridH5] || ![filter isKindOfClass:HNCustomEventObject.class]) {
        return NO;
    }

    return filter.type & HNEventTypeTrack;
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityLow;
}

- (NSDictionary<NSString *,id> *)properties {
    if (!self.filter) {
        return nil;
    }

    return [HNModuleManager.sharedInstance channelInfoWithEvent:self.filter.event];
}
@end
