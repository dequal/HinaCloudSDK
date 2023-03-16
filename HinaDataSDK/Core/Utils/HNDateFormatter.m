//
// HNDateFormatter.m
// HinaDataSDK
//
// Created by hina on 2022/12/23.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDateFormatter.h"

NSString * const kHNEventDateFormatter = @"yyyy-MM-dd HH:mm:ss.SSS";

@implementation HNDateFormatter

+ (NSDateFormatter *)dateFormatterFromString:(NSString *)string {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    });
    if (dateFormatter) {
        [dateFormatter setDateFormat:string];
    }
    return dateFormatter;
}

@end
