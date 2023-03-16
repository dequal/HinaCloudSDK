//
// HNExposureData.h
// HinaDataSDK
//
// Created by hina on 2022/8/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNExposureConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNExposureData : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// init method
/// @param event event name
- (instancetype)initWithEvent:(NSString *)event;

/// init method
/// @param event event name
/// @param properties custom event properties, if no, use nil
- (instancetype)initWithEvent:(NSString *)event properties:(nullable NSDictionary *)properties;

/// init method
/// @param event event name
/// @param properties custom event properties, if no, use nil
/// @param exposureIdentifier identifier for view
- (instancetype)initWithEvent:(NSString *)event properties:(nullable NSDictionary *)properties exposureIdentifier:(nullable NSString *)exposureIdentifier;

/// init method
/// @param event event name
/// @param properties custom event properties, if no, use nil
/// @param config exposure config, if nil, use global config in HNConfigOptions
- (instancetype)initWithEvent:(NSString *)event properties:(nullable NSDictionary *)properties config:(nullable HNExposureConfig *)config;

/// init method
/// @param event event name
/// @param properties custom event properties, if no, use nil
/// @param exposureIdentifier identifier for view
/// @param config exposure config, if nil, use global config in HNConfigOptions
- (instancetype)initWithEvent:(NSString *)event properties:(nullable NSDictionary *)properties exposureIdentifier:(nullable NSString *)exposureIdentifier config:(nullable HNExposureConfig *)config;

@end

NS_ASSUME_NONNULL_END
