//
// HNClassDescription.h
// HinaDataSDK
//
// Created by hina on 1/18/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

@interface HNClassDescription : NSObject

@property (nonatomic, readonly) HNClassDescription *superclassDescription;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSArray *propertyDescriptions;
@property (nonatomic, readonly) NSArray *delegateInfos;

- (instancetype)initWithSuperclassDescription:(HNClassDescription *)superclassDescription dictionary:(NSDictionary *)dictionary;

- (BOOL)isDescriptionForKindOfClass:(Class)class;

@end
