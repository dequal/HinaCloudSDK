//
// HNLoggerConsoleColorFormatter.m
// Logger
//
// Created by hina on 2022/12/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNLoggerConsoleFormatter.h"
#import "HNLogMessage.h"
#import "HNLog+Private.h"

@implementation HNLoggerConsoleFormatter

- (instancetype)init {
    self = [super init];
    if (self) {
        _prefix = @"";
    }
    return self;
}

- (NSString *)formattedLogMessage:(nonnull HNLogMessage *)logMessage {
    NSString *prefixEmoji = @"";
    NSString *levelString = @"";
    switch (logMessage.level) {
        case HNLogLevelError:
            prefixEmoji = @"❌";
            levelString = @"Error";
            break;
        case HNLogLevelWarn:
            prefixEmoji = @"⚠️";
            levelString = @"Warn";
            break;
        case HNLogLevelInfo:
            prefixEmoji = @"ℹ️";
            levelString = @"Info";
            break;
        case HNLogLevelDebug:
            prefixEmoji = @"🛠";
            levelString = @"Debug";
            break;
        case HNLogLevelVerbose:
            prefixEmoji = @"📝";
            levelString = @"Verbose";
            break;
        default:
            break;
    }
    
    NSString *dateString = [[HNLog sharedLog].dateFormatter stringFromDate:logMessage.timestamp];
    NSString *line = [NSString stringWithFormat:@"%lu", logMessage.line];
    return [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ line:%@ %@\n", dateString, prefixEmoji, levelString, self.prefix, logMessage.fileName, logMessage.function, line, logMessage.message];
}

@end
