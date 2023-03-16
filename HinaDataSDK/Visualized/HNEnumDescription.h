//
// HNEnumDescription.h
// HinaDataSDK
//
// Created by hina on 1/18/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>
#import "HNTypeDescription.h"

@interface HNEnumDescription : HNTypeDescription

@property (nonatomic, assign, getter=isFlagsSet, readonly) BOOL flagSet;
@property (nonatomic, copy, readonly) NSString *baseType;

- (NSArray *)allValues; // array of NSNumber instances

@end
