//
// HNExposureData.m
// HinaDataSDK
//
// Created by hina on 2022/8/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNExposureData.h"

@interface HNExposureData ()

@property (nonatomic, copy) NSString *event;
@property (nonatomic, copy) NSDictionary *properties;
@property (nonatomic, copy) NSString *exposureIdentifier;
@property (nonatomic, copy) HNExposureConfig *config;

@end

@implementation HNExposureData

- (instancetype)initWithEvent:(NSString *)event {
    return [self initWithEvent:event properties:nil exposureIdentifier:nil config:nil];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties {
    return [self initWithEvent:event properties:properties exposureIdentifier:nil config:nil];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties exposureIdentifier:(NSString *)exposureIdentifier {
    return [self initWithEvent:event properties:properties exposureIdentifier:exposureIdentifier config:nil];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties config:(HNExposureConfig *)config {
    return [self initWithEvent:event properties:properties exposureIdentifier:nil config:config];
}

- (instancetype)initWithEvent:(NSString *)event properties:(NSDictionary *)properties exposureIdentifier:(NSString *)exposureIdentifier config:(HNExposureConfig *)config {
    self = [super init];
    if (self) {
        _event = event;
        _properties = properties;
        _exposureIdentifier = exposureIdentifier;
        _config = config;
    }
    return self;
}
@end
