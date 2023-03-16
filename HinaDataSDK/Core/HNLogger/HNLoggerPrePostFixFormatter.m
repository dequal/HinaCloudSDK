//
// HNLoggerPrePostFixFormatter.m
// Logger
//
// Created by hina on 2022/12/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNLoggerPrePostFixFormatter.h"
#import "HNLogMessage.h"

@implementation HNLoggerPrePostFixFormatter

- (NSString *)formattedLogMessage:(nonnull HNLogMessage *)logMessage {
    return [NSString stringWithFormat:@"%@ %@ %@", self.prefix, logMessage.message, self.postfix];
}

@end
