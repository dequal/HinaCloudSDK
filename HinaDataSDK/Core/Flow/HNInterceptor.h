//
// HNInterceptor.h
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNFlowData.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNInterceptor : NSObject

@property (nonatomic, strong) HNFlowData *input;
@property (nonatomic, strong) HNFlowData *output;

+ (instancetype)interceptorWithParam:(NSDictionary * _Nullable)param;

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion;

@end

NS_ASSUME_NONNULL_END
