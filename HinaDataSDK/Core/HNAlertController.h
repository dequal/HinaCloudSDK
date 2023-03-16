//
// HNAlertController.h
// HinaDataSDK
//
// Created by hina on 2022/3/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#endif

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSUInteger, HNAlertActionStyle) {
    HNAlertActionStyleDefault,
    HNAlertActionStyleCancel,
    HNAlertActionStyleDestructive
};

typedef NS_ENUM(NSUInteger, HNAlertControllerStyle) {
    HNAlertControllerStyleActionSheet = 0,
    HNAlertControllerStyleAlert
};

@interface HNAlertAction : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic) HNAlertActionStyle style;
@property (nonatomic, copy) void (^handler)(HNAlertAction *);

@property (nonatomic, readonly) NSInteger tag;

+ (instancetype)actionWithTitle:(nullable NSString *)title style:(HNAlertActionStyle)style handler:(void (^ __nullable)(HNAlertAction *))handler;

@end

#if TARGET_OS_IOS
/**
 海纳弹框的 HNAlertController，添加到黑名单。
 防止 $AppViewScreen 事件误采
 内部使用 UIAlertController 实现
 */
@interface HNAlertController : UIViewController


/**
 HNAlertController 初始化，⚠️ 注意 ActionSheet 样式不支持 iPad❗️❗️❗️

 @param title 标题
 @param message 提示信息
 @param preferredStyle 弹框类型
 @return HNAlertController
 */
- (instancetype)initWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(HNAlertControllerStyle)preferredStyle;


/**
 添加一个 Action

 @param title Action 显示的 title
 @param style Action 的类型
 @param handler 回调处理方法，带有这个 Action 本身参数
 */
- (void)addActionWithTitle:(NSString *_Nullable)title style:(HNAlertActionStyle)style handler:(void (^ __nullable)(HNAlertAction *))handler;


/**
 显示 HNAlertController
 */
- (void)show;

@end

#endif

NS_ASSUME_NONNULL_END
