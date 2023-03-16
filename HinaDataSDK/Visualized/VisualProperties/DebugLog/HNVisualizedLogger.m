//
// HNVisualizedDebugLogger.m
// HinaDataSDK
//
// Created by hina on 2022/4/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNVisualizedLogger.h"
#import <UIKit/UIKit.h>

/// 日志过滤前缀
static NSString * const kHNVisualizedLoggerPrefix = @"HNVisualizedDebugLoggerPrefix:";

/// 日志的 title 和 messsage 分隔符
static NSString * const kHNVisualizedLoggerSeparatedChar = @"：";

@implementation HNLoggerVisualizedFormatter

- (NSString *)formattedLogMessage:(HNLogMessage *)logMessage {
    return logMessage.message;
}
@end


@implementation HNVisualizedLogger

- (instancetype)init {
    self = [super init];
    if (self) {
        self.loggerQueue = dispatch_queue_create("cn.hinadata.HNVisualizedLoggerSerialQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark logMessage
- (void)logMessage:(HNLogMessage *)logMessage {
    [super logMessage:logMessage];

    HNLoggerVisualizedFormatter *formatter = [[HNLoggerVisualizedFormatter alloc] init];

    // 获取日志
    NSString *message = [formatter formattedLogMessage:logMessage];

    // 筛选自定义属性日志
    if (![message containsString:kHNVisualizedLoggerPrefix]) {
        return;
    }
    NSRange range = [message rangeOfString:kHNVisualizedLoggerPrefix];

    NSString *debugLog = [message substringFromIndex:range.location + range.length];

    // 格式校验
    if (![debugLog containsString:kHNVisualizedLoggerSeparatedChar]) {
        return;
    }

    NSRange separatedRange = [debugLog rangeOfString:kHNVisualizedLoggerSeparatedChar];
    NSString *loggerTitle = [debugLog substringToIndex:separatedRange.location];
    NSString *loggerMessage = [debugLog substringFromIndex:separatedRange.location + separatedRange.length];
    if (!loggerTitle || !loggerMessage) {
        return;
    }
    NSDictionary *messageDic = @{@"title": loggerTitle, @"message":loggerMessage};
    // 日志信息
    if (self.delegate && [self.delegate respondsToSelector:@selector(loggerMessage:)]) {
        [self.delegate loggerMessage:messageDic];
    }
}

@end

#pragma mark -
@implementation HNVisualizedLogger (Build)

+ (NSString *)buildLoggerMessageWithTitle:(NSString *)title message:(NSString *)format, ... {
    NSMutableString *logMessage = [NSMutableString stringWithString:kHNVisualizedLoggerPrefix];
    if (title) { // 拼接标题
        [logMessage appendString:title];
        [logMessage appendString:kHNVisualizedLoggerSeparatedChar];
    }

    //in iOS10, initWithFormat: arguments: crashed when format string contain special char "%" but no escaped, like "%2434343%rfrfrfrf%".
#ifndef DEBUG
    if ([[[UIDevice currentDevice] systemVersion] integerValue] == 10) {
        return title;
    }
#endif
    if (!format) {
        return title;
    }
    
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    if (message) { // 拼接内容
        [logMessage appendString:message];
    }
    return [logMessage copy];
}

@end
