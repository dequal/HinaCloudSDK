//
// HNLogMessage.h
// Logger
//
// Created by hina on 2022/12/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>
#import "HNLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNLogMessage : NSObject

@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, assign, readonly) HNLogLevel level;
@property (nonatomic, copy, readonly) NSString *file;
@property (nonatomic, copy, readonly) NSString *fileName;
@property (nonatomic, copy, readonly) NSString *function;
@property (nonatomic, assign, readonly) NSUInteger line;
@property (nonatomic, assign, readonly) NSInteger context;
@property (nonatomic, strong, readonly) NSDate *timestamp;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithMessage:(NSString *)message
                          level:(HNLogLevel)level
                           file:(NSString *)file
                       function:(NSString *)function
                           line:(NSUInteger)line
                        context:(NSInteger)context
                      timestamp:(NSDate *)timestamp NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
