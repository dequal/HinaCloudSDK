//
// HNLoggerPrePostFixFormatter.h
// Logger
//
// Created by hina on 2022/12/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>
#import "HNLog+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNLoggerPrePostFixFormatter : NSObject <HNLogMessageFormatter>

@property (nonatomic, copy) NSString *prefix;
@property (nonatomic, copy) NSString *postfix;

@end

NS_ASSUME_NONNULL_END
