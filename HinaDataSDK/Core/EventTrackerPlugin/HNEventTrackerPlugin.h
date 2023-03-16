//
// HNEventTrackerPlugin.h
// HinaDataSDK
//
// Created by hina on 2022/11/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNEventTrackerPlugin : NSObject

@property (nonatomic, readonly) NSString *type;
@property (nonatomic, assign) BOOL enable;

@end

NS_ASSUME_NONNULL_END
