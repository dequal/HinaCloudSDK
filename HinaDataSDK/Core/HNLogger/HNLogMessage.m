//
// HNLogMessage.m
// Logger
//
// Created by hina on 2022/12/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNLogMessage.h"

@implementation HNLogMessage

- (instancetype)initWithMessage:(NSString *)message level:(HNLogLevel)level file:(NSString *)file function:(NSString *)function line:(NSUInteger)line context:(NSInteger)context timestamp:(NSDate *)timestamp {
    if (self = [super init]) {
        _message = message;
        _level = level;
        _file = file;
        _function = function;
        _line = line;
        _context = context;
        _timestamp = timestamp;
        _fileName = file.lastPathComponent;
    }
    return self;
}

@end
