//
// HNTypeDescription.h
// HinaDataSDK
//
// Created by hina on 1/18/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

@interface HNTypeDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSString *name;

@end