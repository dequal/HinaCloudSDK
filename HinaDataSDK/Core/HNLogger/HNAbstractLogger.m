//
// HNAbstractLogger.m
// Logger
//
// Created by hina on 2022/12/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAbstractLogger.h"
#import <pthread.h>

@implementation HNAbstractLogger

- (void)logMessage:(nonnull HNLogMessage *)logMessage {
    // base implementation
}

@end
