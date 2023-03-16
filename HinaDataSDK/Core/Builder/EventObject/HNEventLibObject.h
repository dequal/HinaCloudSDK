//
// HNEventLibObject.h
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNPropertyPlugin.h"

NS_ASSUME_NONNULL_BEGIN

/// SDK 类型
extern NSString * const kHNEventPresetPropertyLib;
/// SDK 方法
extern NSString * const kHNEventPresetPropertyLibMethod;
/// SDK 版本
extern NSString * const kHNEventPresetPropertyLibVersion;
/// SDK 调用栈
extern NSString * const kHNEventPresetPropertyLibDetail;
/// 应用版本
extern NSString * const kHNEventPresetPropertyAppVersion;

@interface HNEventLibObject : NSObject <HNPropertyPluginLibFilter>

@property (nonatomic, copy) NSString *lib;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSString *version;
@property (nonatomic, strong) id appVersion;
@property (nonatomic, copy, nullable) NSString *detail;

- (NSMutableDictionary *)jsonObject;

- (instancetype)initWithH5Lib:(NSDictionary *)lib;

@end

NS_ASSUME_NONNULL_END
