//
// HNDateFormatter.h
// HinaDataSDK
//
// Created by hina on 2022/12/23.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kHNEventDateFormatter;

@interface HNDateFormatter : NSObject

/**
*  @abstract
*  获取 NSDateFormatter 单例对象
*
*  @param string 日期格式
*
*  @return 返回 NSDateFormatter 单例对象
*/
+ (NSDateFormatter *)dateFormatterFromString:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
