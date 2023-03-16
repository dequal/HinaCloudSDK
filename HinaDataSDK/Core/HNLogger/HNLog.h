//
// HNLog.h
// Logger
//
// Created by hina on 2022/12/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define HINA_ANALYTICS_LOG_MACRO(isAsynchronous, lvl, fnct, ctx, frmt, ...) \
[HNLog log : isAsynchronous                                     \
     level : lvl                                                \
      file : __FILE__                                           \
  function : fnct                                               \
      line : __LINE__                                           \
   context : ctx                                                \
    format : (frmt), ## __VA_ARGS__]


#define HNLogError(frmt, ...)   HINA_ANALYTICS_LOG_MACRO(YES, HNLogLevelError, __PRETTY_FUNCTION__, 0, frmt, ##__VA_ARGS__)
#define HNLogWarn(frmt, ...)   HINA_ANALYTICS_LOG_MACRO(YES, HNLogLevelWarn, __PRETTY_FUNCTION__, 0, frmt, ##__VA_ARGS__)
#define HNLogInfo(frmt, ...)   HINA_ANALYTICS_LOG_MACRO(YES, HNLogLevelInfo, __PRETTY_FUNCTION__, 0, frmt, ##__VA_ARGS__)
#define HNLogDebug(frmt, ...)   HINA_ANALYTICS_LOG_MACRO(YES, HNLogLevelDebug, __PRETTY_FUNCTION__, 0, frmt, ##__VA_ARGS__)
#define HNLogVerbose(frmt, ...)   HINA_ANALYTICS_LOG_MACRO(YES, HNLogLevelVerbose, __PRETTY_FUNCTION__, 0, frmt, ##__VA_ARGS__)


typedef NS_OPTIONS(NSUInteger, HNLogLevel) {
    HNLogLevelError = (1 << 0),
    HNLogLevelWarn = (1 << 1),
    HNLogLevelInfo = (1 << 2),
    HNLogLevelDebug = (1 << 3),
    HNLogLevelVerbose = (1 << 4)
};


@interface HNLog : NSObject

+ (instancetype)sharedLog;

@property (atomic, assign) BOOL enableLog;

+ (void)log:(BOOL)asynchronous
      level:(HNLogLevel)level
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
    context:(NSInteger)context
     format:(NSString *)format, ... NS_FORMAT_FUNCTION(7, 8);

- (void)log:(BOOL)asynchronous
   level:(HNLogLevel)level
    file:(const char *)file
function:(const char *)function
    line:(NSUInteger)line
 context:(NSInteger)context
  format:(NSString *)format, ... NS_FORMAT_FUNCTION(7, 8);

@end

NS_ASSUME_NONNULL_END
