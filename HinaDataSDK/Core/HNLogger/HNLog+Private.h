//
// HNLog+Private.h
// HinaDataSDK
//
// Created by hina on 2022/3/27.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNAbstractLogger.h"

@interface HNLog (Private)

@property (nonatomic, strong, readonly) NSDateFormatter *dateFormatter;

+ (void)addLogger:(HNAbstractLogger<HNLogger> *)logger;
+ (void)addLoggers:(NSArray<HNAbstractLogger<HNLogger> *> *)loggers;
+ (void)removeLogger:(HNAbstractLogger<HNLogger> *)logger;
+ (void)removeLoggers:(NSArray<HNAbstractLogger<HNLogger> *> *)loggers;
+ (void)removeAllLoggers;

- (void)addLogger:(HNAbstractLogger<HNLogger> *)logger;
- (void)addLoggers:(NSArray<HNAbstractLogger<HNLogger> *> *)loggers;
- (void)removeLogger:(HNAbstractLogger<HNLogger> *)logger;
- (void)removeLoggers:(NSArray<HNAbstractLogger<HNLogger> *> *)loggers;
- (void)removeAllLoggers;

@end
