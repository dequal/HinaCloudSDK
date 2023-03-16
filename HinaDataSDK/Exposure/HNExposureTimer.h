//
// HNExposureTimer.h
// HinaDataSDK
//
// Created by hina on 2022/8/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNExposureTimer : NSObject

@property (nonatomic, copy, nullable) void (^completeBlock)(void);

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDuration:(NSTimeInterval)duration completeBlock:(nullable void (^)(void))completeBlock;

- (void)start;
- (void)stop;

- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
