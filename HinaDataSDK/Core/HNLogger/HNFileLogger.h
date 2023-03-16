//
// HNFileLogger.h
// Logger
//
// Created by hina on 2022/12/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>
#import "HNAbstractLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNFileLogger : HNAbstractLogger

@property (nonatomic, assign) HNLogLevel fileLogLevel;

@end

NS_ASSUME_NONNULL_END