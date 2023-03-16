//
// HNVisualizedViewPathProperty.h
// HinaDataSDK
//
// Created by hina on 2022/3/28.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//


#import <Foundation/Foundation.h>


#pragma mark - Visualized
// 可视化全埋点&点击分析 上传页面信息相关协议
@protocol HNVisualizedViewPathProperty <NSObject>

@optional
/// 当前元素，前端是否渲染成可交互
@property (nonatomic, assign, readonly) BOOL hinadata_enableAppClick;

/// 当前元素的有效内容
@property (nonatomic, copy, readonly) NSString *hinadata_elementValidContent;

/// 元素子视图
@property (nonatomic, copy, readonly) NSArray *hinadata_subElements;

/// App 内嵌 H5 元素的元素选择器
@property (nonatomic, copy, readonly) NSString *hinadata_elementSelector;

/// 相对 keywindow 的坐标
@property (nonatomic, assign, readonly) CGRect hinadata_frame;

/// 当前元素所在页面名称
@property (nonatomic, copy, readonly) NSString *hinadata_screenName;

/// 当前元素所在页面标题
@property (nonatomic, copy, readonly) NSString *hinadata_title;

/// 是否为 Web 元素
@property (nonatomic, assign) BOOL hinadata_isFromWeb;

/// 是否为列表（本身支持限定位置，比如 Cell）
@property (nonatomic, assign) BOOL hinadata_isListView;

/// 元素所在平台
///
/// 区分不同平台的元素（ios/h5/flutter）,Flutter 和其他平台，不支持混合圈选（事件和属性元素属于不同平台），需要给予屏蔽
@property (nonatomic, copy) NSString *hinadata_platform;


@end

#pragma mark - Extension
@protocol HNVisualizedExtensionProperty <NSObject>

@optional
/// 一个 view 上子视图可见区域
@property (nonatomic, assign, readonly) CGRect hinadata_visibleFrame;

/// 是否禁用 RCTView 子视图交互
@property (nonatomic, assign) BOOL hinadata_isDisableRNSubviewsInteractive;
@end
