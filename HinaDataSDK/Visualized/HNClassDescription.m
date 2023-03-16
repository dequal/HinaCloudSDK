//
// HNClassDescription.m
// HinaDataSDK
//
// Created by hina on 1/18/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "HNClassDescription.h"
#import "HNPropertyDescription.h"

@implementation HNClassDescription {
    NSArray *_propertyDescriptions;
}

- (instancetype)initWithSuperclassDescription:(HNClassDescription *)superclassDescription
                                   dictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        _superclassDescription = superclassDescription;
        _name = dictionary[@"name"];
        NSMutableArray *propertyDescriptions = [NSMutableArray array];
        for (NSDictionary *propertyDictionary in dictionary[@"attr"]) {
            [propertyDescriptions addObject:[[HNPropertyDescription alloc] initWithDictionary:propertyDictionary]];
        }

        _propertyDescriptions = [propertyDescriptions copy];
    }

    return self;
}

- (NSArray *)propertyDescriptions {
    NSMutableDictionary *allPropertyDescriptions = [[NSMutableDictionary alloc] init];

    HNClassDescription *description = self;
    while (description)
    {
        for (HNPropertyDescription *propertyDescription in description->_propertyDescriptions) {
            if (!allPropertyDescriptions[propertyDescription.name]) {
                allPropertyDescriptions[propertyDescription.name] = propertyDescription;
            }
        }
        description = description.superclassDescription;
    }

    return [allPropertyDescriptions allValues];
}

- (BOOL)isDescriptionForKindOfClass:(Class)class {
    return [self.name isEqualToString:NSStringFromClass(class)] && [self.superclassDescription isDescriptionForKindOfClass:[class superclass]];
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@:%p name='%@' superclass='%@'>", NSStringFromClass([self class]), (__bridge void *)self, self.name, self.superclassDescription ? self.superclassDescription.name : @""];
}

@end
