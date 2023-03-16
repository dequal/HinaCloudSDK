//
// HNReferrerManager.h
// HinaDataSDK
//
// Created by hina on 2022/12/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNReferrerManager : NSObject

@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, assign) BOOL isClearReferrer;

@property (atomic, copy, readonly) NSDictionary *referrerProperties;
@property (atomic, copy, readonly) NSString *referrerURL;
@property (nonatomic, copy, readonly) NSString *referrerTitle;

+ (instancetype)sharedInstance;

- (NSDictionary *)propertiesWithURL:(NSString *)currentURL eventProperties:(NSDictionary *)eventProperties;

- (void)clearReferrer;

@end

NS_ASSUME_NONNULL_END
