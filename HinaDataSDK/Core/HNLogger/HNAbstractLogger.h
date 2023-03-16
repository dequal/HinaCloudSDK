//
// HNAbstractLogger.h
// Logger
//
// Created by hina on 2022/12/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>
#import "HNLogMessage.h"

NS_ASSUME_NONNULL_BEGIN

@protocol HNLogger <NSObject>

@required
- (void)logMessage:(HNLogMessage *)logMessage;

@end


@protocol HNLogMessageFormatter <NSObject>

@required
- (NSString *)formattedLogMessage:(HNLogMessage *)logMessage;

@end

@interface HNAbstractLogger : NSObject <HNLogger>

@property (nonatomic, strong) dispatch_queue_t loggerQueue;

@end

NS_ASSUME_NONNULL_END
