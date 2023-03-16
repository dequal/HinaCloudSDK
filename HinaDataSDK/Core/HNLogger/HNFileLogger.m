//
// HNFileLogger.m
// Logger
//
// Created by hina on 2022/12/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNFileLogger.h"
#import "HNLoggerConsoleFormatter.h"

@interface HNFileLogger ()

@property (nonatomic, copy) NSString *logFilePath;
@property (nonatomic, strong) NSFileHandle *fileHandle;
@property (nonatomic, strong) HNLoggerConsoleFormatter *formatter;

@end

@implementation HNFileLogger

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileLogLevel = HNLogLevelVerbose;
    }
    return self;
}

- (void)logMessage:(HNLogMessage *)logMessage {
    [super logMessage:logMessage];
    if (logMessage.level > self.fileLogLevel) {
        return;
    }
    [self writeLogMessage:logMessage];
}

- (NSString *)logFilePath {
    if (!_logFilePath) {
        _logFilePath = [self currentlogFile];
    }
    return _logFilePath;
}

- (NSFileHandle *)fileHandle {
    if (!_fileHandle) {
        _fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFilePath];
    }
    return _fileHandle;
}

- (HNLoggerConsoleFormatter *)formatter {
    if (!_formatter) {
        _formatter = [[HNLoggerConsoleFormatter alloc] init];
    }
    return _formatter;
}

- (nullable NSString *)currentlogFile {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *logfilePath = [path stringByAppendingPathComponent:@"HNLog/HNLog.log"];
    BOOL fileExists = [manager fileExistsAtPath:logfilePath];
    if (fileExists) {
        return logfilePath;
    }
    NSError *error;
    BOOL directoryCreated = [manager createDirectoryAtPath:[logfilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
    if (!directoryCreated) {
        NSLog(@"HNFileLogger file directory created failed");
        return nil;
    }
    NSDictionary *attributes = nil;
#if TARGET_OS_IOS
    attributes = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
#endif
    BOOL fileCreated = [[NSFileManager defaultManager] createFileAtPath:logfilePath contents:nil attributes:attributes];
    if (!fileCreated) {
        NSLog(@"HNFileLogger file created failed");
        return nil;
    }
    return logfilePath;
}

- (void)writeLogMessage:(HNLogMessage *)logMessage {
    if (!self.fileHandle) {
        return;
    }
    NSString *formattedMessage = [self.formatter formattedLogMessage:logMessage];
    @try {
        [self.fileHandle seekToEndOfFile];
        [self.fileHandle writeData:[formattedMessage dataUsingEncoding:NSUTF8StringEncoding]];
    } @catch (NSException *exception) {
        NSLog(@"HNFileLogger logMessage: %@", exception);
    } @finally {
        // any final action
    }
}

@end
