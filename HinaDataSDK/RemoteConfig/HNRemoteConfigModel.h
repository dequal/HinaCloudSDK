//
// HNRemoteConfigModel.h
// HinaDataSDK
//
// Created by hina on 2022/7/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

// -1，表示不修改现有的 autoTrack 方式；0 代表禁用所有的 autoTrack；其他 1～15 为合法数据
static NSInteger kHNAutoTrackModeDefault = -1;
static NSInteger kHNAutoTrackModeDisabledAll = 0;
static NSInteger kHNAutoTrackModeEnabledAll = 15;

typedef NS_ENUM(NSInteger, HNRemoteConfigEffectMode) {
    HNRemoteConfigEffectModeNext = 0, // 远程配置下次启动生效
    HNRemoteConfigEffectModeNow = 1,  // 远程配置立即生效
};

@interface HNRemoteConfigModel : NSObject

@property (nonatomic, copy) NSString *originalVersion; // 远程配置的老版本号（对应通过运维修改的配置）
@property (nonatomic, copy) NSString *latestVersion; // 远程配置的新版本号（对应通过远程配置页面修改的配置）
/// ⚠️ 注意：存在 KVC 获取，不要修改属性名称❗️❗️❗️
@property (nonatomic, assign) BOOL disableSDK;
/// ⚠️ 注意：存在 KVC 获取，不要修改属性名称❗️❗️❗️
@property (nonatomic, assign) BOOL disableDebugMode;
@property (nonatomic, assign) NSInteger autoTrackMode; // -1, 0, 1~15
@property (nonatomic, copy) NSArray<NSString *> *eventBlackList;
@property (nonatomic, assign) HNRemoteConfigEffectMode effectMode;
@property (nonatomic, copy) NSString *localLibVersion; // 本地保存 SDK 版本号

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)toDictionary;

@end
