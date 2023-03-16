//
// HNFirstDayPropertyPlugin.m
// HinaDataSDK
//
// Created by  hina on 2022/5/5.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNFirstDayPropertyPlugin.h"
#import "HNStoreManager.h"
#import "HNDateFormatter.h"
#import "HNConstants+Private.h"


/// 是否首日
NSString * const kHNPresetPropertyIsFirstDay = @"H_is_first_day";

@interface HNFirstDayPropertyPlugin()

@property (nonatomic, copy) NSString *firstDay;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation HNFirstDayPropertyPlugin

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;
        dispatch_async(queue, ^{
            [self unarchiveFirstDay];
        });
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self unarchiveFirstDay];
    }
    return self;
}

- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter {
    // 是否首日访问，只有 track/bind/unbind 事件添加 H_is_first_day 属性
    return filter.type & (HNEventTypeTrack | HNEventTypeBind | HNEventTypeUnbind);
}

- (HNPropertyPluginPriority)priority {
    return HNPropertyPluginPriorityHigh;
}

- (void)prepare {
    [self readyWithProperties:@{kHNPresetPropertyIsFirstDay: @([self isFirstDay])}];
}

#pragma mark – Public Methods
- (BOOL)isFirstDay {
    __block BOOL isFirstDay = NO;
    dispatch_block_t readFirstDayBlock = ^(){
        NSDateFormatter *dateFormatter = [HNDateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
        NSString *current = [dateFormatter stringFromDate:[NSDate date]];
        isFirstDay = [self.firstDay isEqualToString:current];
    };

    if (self.queue) {
        hinadata_dispatch_safe_sync(self.queue, readFirstDayBlock);
    } else {
        readFirstDayBlock();
    }
    return isFirstDay;
}

#pragma mark – Private Methods
- (void)unarchiveFirstDay {
    self.firstDay = [[HNStoreManager sharedInstance] objectForKey:@"first_day"];
    if (!self.firstDay) {
        NSDateFormatter *dateFormatter = [HNDateFormatter dateFormatterFromString:@"yyyy-MM-dd"];
        self.firstDay = [dateFormatter stringFromDate:[NSDate date]];
        [[HNStoreManager sharedInstance] setObject:self.firstDay forKey:@"first_day"];
    }
}

@end
