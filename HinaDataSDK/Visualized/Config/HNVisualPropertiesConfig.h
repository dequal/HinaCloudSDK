//
// HNVisualPropertiesConfig.h
// HinaDataSDK
//
// Created by hina on 2022/1/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HinaDataSDK+Private.h"

/**
 * @abstract
 * 属性类型
 *
 * @discussion
 * 自定义属性类型
 *   HNVisualPropertyTypeString - 字符型
 *   HNVisualPropertyTypeNumber - 数值型
 */
typedef NS_ENUM(NSInteger, HNVisualPropertyType) {
    HNVisualPropertyTypeString,
    HNVisualPropertyTypeNumber
};

NS_ASSUME_NONNULL_BEGIN

/// view 标识，包含页面名称、路径等
@interface HNViewIdentifier : NSObject<NSCoding>

/// 元素路径
@property (nonatomic, copy) NSString *elementPath;

/// 元素所在页面
@property (nonatomic, copy) NSString *screenName;

/// 元素位置
@property (nonatomic, copy) NSString *elementPosition;

/// 元素内容
@property (nonatomic, copy) NSString *elementContent;

/*
 当前同类页面序号
 -1：同级只存在一个同类页面，不需要用比较 pageIndex
 >=0：同级同类页面序号序号
 */
@property (nonatomic, assign) NSInteger pageIndex;

- (instancetype)initWithDictionary:(NSDictionary *)dic;

- (instancetype)initWithView:(UIView *)view;

- (BOOL)isEqualToViewIdentify:(HNViewIdentifier *)object;

@end


/// 属性绑定的事件配置
@interface HNVisualPropertiesEventConfig : HNViewIdentifier<NSCoding>

/// 是否限制元素位置
@property (nonatomic, assign, getter=isLimitPosition) BOOL limitPosition;

/// 是否限制元素内容
@property (nonatomic, assign, getter=isLimitContent) BOOL limitContent;

/// 是否为 H5 事件
@property (nonatomic, assign, getter=isH5) BOOL h5;

/// 当前事件配置，是否命中元素
- (BOOL)isMatchVisualEventWithViewIdentify:(HNViewIdentifier *)viewIdentify;
@end

/// 属性绑定的属性配置
@interface HNVisualPropertiesPropertyConfig : HNViewIdentifier<NSCoding>

/// 属性名
@property (nonatomic, copy) NSString *name;

@property (nonatomic, assign) HNVisualPropertyType type;

// 属性正则表达式
@property (nonatomic, copy) NSString *regular;

/// 是否限制元素位置
@property (nonatomic, assign, getter=isLimitPosition) BOOL limitPosition;

/// 是否为 H5 属性
@property (nonatomic, assign, getter=isH5) BOOL h5;

/// webview 的元素路径，App 内嵌 H5 属性配置才包含
@property (nonatomic, copy) NSString *webViewElementPath;

/* 本地扩展，用于元素匹配 */
/// 点击事件所在元素位置，点击元素传值
@property (nonatomic, copy) NSString *clickElementPosition;

/// 当前属性配置，是否命中元素
/// @param viewIdentify 元素节点
/// @return 是否命中
- (BOOL)isMatchVisualPropertiesWithViewIdentify:(HNViewIdentifier *)viewIdentify;
@end

/// 属性绑定配置信息
@interface HNVisualPropertiesConfig : NSObject<NSCoding>

/// 事件类型，目前只支持 AppClick
@property (nonatomic, assign) HinaDataAutoTrackEventType eventType;

/// 定义的事件名称
@property (nonatomic, copy) NSString *eventName;

/// 事件配置
@property (nonatomic, strong) HNVisualPropertiesEventConfig *event;

/// 属性配置
@property (nonatomic, strong) NSArray<HNVisualPropertiesPropertyConfig *> *properties;

/// web 属性配置，原始配置 json
@property (nonatomic, strong) NSArray<NSDictionary *> *webProperties;
@end


@interface HNVisualPropertiesResponse : NSObject<NSCoding>

@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *project;
@property (nonatomic, copy) NSString *appId;

// 系统
@property (nonatomic, copy) NSString *os;
@property (nonatomic, strong) NSArray<HNVisualPropertiesConfig *> *events;

/// 原始配置 json 数据
@property (nonatomic, copy) NSDictionary *originalResponse;

- (instancetype)initWithDictionary:(NSDictionary *)responseDic;
@end

NS_ASSUME_NONNULL_END
