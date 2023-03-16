//
// HNObjectSerializerConfig.m
// HinaDataSDK
//
// Created by hina on 1/18/16.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import "HNClassDescription.h"
#import "HNObjectSerializerConfig.h"

@implementation HNObjectSerializerConfig {
    NSDictionary *_classes;
    NSDictionary *_enums;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        NSMutableDictionary *classDescriptions = [[NSMutableDictionary alloc] init];
        for (NSDictionary *d in dictionary[@"classes"]) {
            NSString *superclassName = d[@"superclass"];
            HNClassDescription *superclassDescription = superclassName ? classDescriptions[superclassName] : nil;
            
            // 构造一个类的描述信息
            HNClassDescription *classDescription = [[HNClassDescription alloc] initWithSuperclassDescription:superclassDescription dictionary:d];

            classDescriptions[classDescription.name] = classDescription;
        }
 
        _classes = [classDescriptions copy];
    }

    return self;
}

- (NSArray *)classDescriptions {
    return [_classes allValues];
}

- (HNClassDescription *)classWithName:(NSString *)name {
    return _classes[name];
}
@end
