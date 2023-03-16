//
// HNExposureManager.h
// HinaDataSDK
//
// Created by hina on 2022/8/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNConfigOptions.h"
#import "HNModuleProtocol.h"
#import "HNExposureViewObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNExposureManager : NSObject <HNModuleProtocol>

- (instancetype)init NS_UNAVAILABLE;

/// singleton instance
+ (instancetype)defaultManager;

@property (nonatomic, strong) HNConfigOptions *configOptions;
@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) NSMutableArray<HNExposureViewObject *> *exposureViewObjects;

- (void)addExposureView:(UIView *)view withData:(HNExposureData *)data;
- (void)removeExposureView:(UIView *)view withExposureIdentifier:(nullable NSString *)identifier;

- (HNExposureViewObject *)exposureViewWithView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
