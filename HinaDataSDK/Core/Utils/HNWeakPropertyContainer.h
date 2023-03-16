//
// HNWeakPropertyContainer.h
// HinaDataSDK
//
// Created by hina on 2022/8/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

@interface HNWeakPropertyContainer : NSObject

@property (readonly, nonatomic, weak) id weakProperty;

+ (instancetype)containerWithWeakProperty:(id)weakProperty;

@end
