//
// NSObject+HNToString.m
// HinaDataSDK
//
// Created by hina on 2022/11/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "NSObject+HNToString.h"
#import "HNDateFormatter.h"

@implementation NSObject (HNToString)

- (NSString *)hinadata_toString {
    if ([self isKindOfClass:[NSString class]]) {
        return (NSString *)self;
    }
    if ([self isKindOfClass:[NSDate class]]) {
        NSDateFormatter *dateFormatter = [HNDateFormatter dateFormatterFromString:kHNEventDateFormatter];
        return [dateFormatter stringFromDate:(NSDate *)self];
    }
    return self.description;
}

@end
