//
// HNVisualizedLogger.h
// HinaDataSDK
//
// Created by hina on 2022/4/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNAbstractLogger.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HNVisualizedLoggerDelegate <NSObject>

- (void)loggerMessage:(NSDictionary *)messageDic;

@end

@interface HNLoggerVisualizedFormatter : NSObject <HNLogMessageFormatter>

@end


/// 自定义属性日志打印
@interface HNVisualizedLogger : HNAbstractLogger

@property (weak, nonatomic, nullable) id<HNVisualizedLoggerDelegate> delegate;

@end

#pragma mark -
@interface HNVisualizedLogger(Build)

/// 构建 log 日志
/// @param title 日志标题
/// @param format 日志详情拼接
+ (NSString *)buildLoggerMessageWithTitle:(NSString *)title message:(NSString *)format, ...;

@end

NS_ASSUME_NONNULL_END
