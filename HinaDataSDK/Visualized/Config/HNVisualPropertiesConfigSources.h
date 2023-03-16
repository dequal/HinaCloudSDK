//
// HNVisualPropertiesConfigSources.h
// HinaDataSDK
//
// Created by hina on 2022/1/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNVisualPropertiesConfig.h"
#import "HNEventIdentifier.h"
#import "HNViewNode.h"

NS_ASSUME_NONNULL_BEGIN

@class HNVisualPropertiesConfigSources;
/// 配置改变的监听
@protocol HNConfigChangesDelegate <NSObject>

- (void)configChangedWithValid:(BOOL)valid;

@end


/// 配置数据管理
@interface HNVisualPropertiesConfigSources : NSObject

/// 配置是否有效
@property (nonatomic, assign, readonly, getter=isValid) BOOL valid;

/// 配置版本
@property (nonatomic, copy, readonly) NSString *configVersion;

/// 配置原始 json
@property (nonatomic, copy, readonly) NSDictionary *originalResponse;

/// 指定初始化方法，设置配置信息更新代理
/// @param delegate 设置代理
/// @return 实例对象
- (instancetype)initWithDelegate:(id<HNConfigChangesDelegate>)delegate NS_DESIGNATED_INITIALIZER;

/// 禁用默认初始化
- (instancetype)init NS_UNAVAILABLE;
/// 禁用默认初始化
+ (instancetype)new NS_UNAVAILABLE;

/// 加载配置
- (void)loadConfig;

/// 设置配置数据
/// @param configDic 可视化全埋点配置 json
/// @param disable 是否禁用自定义属性
- (void)setupConfigWithDictionary:(nullable NSDictionary *)configDic disableConfig:(BOOL)disable;

/// 更新配置（切换 serverURL）
- (void)reloadConfig;

/// 查询元素对应事件配置
- (nullable NSArray <HNVisualPropertiesConfig *> *)propertiesConfigsWithViewNode:(HNViewNode *)viewNode;

/// 根据事件信息查询配置
- (nullable NSArray <HNVisualPropertiesConfig *> *)propertiesConfigsWithEventIdentifier:(HNEventIdentifier *)eventIdentifier;

@end

NS_ASSUME_NONNULL_END
