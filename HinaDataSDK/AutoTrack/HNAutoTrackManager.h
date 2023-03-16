//
// HNAutoTrackManager.h
// HinaDataSDK
//
// Created by hina on 2022/4/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNModuleProtocol.h"
#import "HNAppClickTracker.h"
#import "HNAppViewScreenTracker.h"
#import "HNAppPageLeaveTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNConfigOptions (AutoTrackPrivate)

@property (nonatomic, assign) BOOL enableAutoTrack;

@end

@interface HNAutoTrackManager : NSObject <HNModuleProtocol, HNAutoTrackModuleProtocol>

@property (nonatomic, strong) HNConfigOptions *configOptions;
@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) HNAppClickTracker *appClickTracker;
@property (nonatomic, strong) HNAppViewScreenTracker *appViewScreenTracker;
@property (nonatomic, strong) HNAppPageLeaveTracker *appPageLeaveTracker;

+ (HNAutoTrackManager *)defaultManager;

#pragma mark - Public

/// 是否开启全埋点
- (BOOL)isAutoTrackEnabled;

/// 是否忽略某些全埋点
/// @param eventType 全埋点类型
- (BOOL)isAutoTrackEventTypeIgnored:(HinaDataAutoTrackEventType)eventType;

/// 更新全埋点事件类型
- (void)updateAutoTrackEventType;

/// 校验可视化全埋点元素能否选中
/// @param obj 控件元素
/// @return 返回校验结果
- (BOOL)isGestureVisualView:(id)obj;

@end

NS_ASSUME_NONNULL_END
