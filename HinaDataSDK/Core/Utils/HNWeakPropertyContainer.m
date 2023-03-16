//
// HNWeakPropertyContainer.m
// HinaDataSDK
//
// Created by hina on 2022/8/8.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNWeakPropertyContainer.h"

@interface HNWeakPropertyContainer ()
 
@property (nonatomic, weak) id weakProperty;

@end

@implementation HNWeakPropertyContainer

+ (instancetype)containerWithWeakProperty:(id)weakProperty {
    HNWeakPropertyContainer *container = [[HNWeakPropertyContainer alloc]init];
    container.weakProperty = weakProperty;
    return container;
}

@end
