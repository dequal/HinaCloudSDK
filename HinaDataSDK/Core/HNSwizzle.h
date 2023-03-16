// HNSwizzler.h
// HinaDataSDK
//
// Created by hina on 1/20/16
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (HNSwizzle)

+ (BOOL)sa_swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError **)error_;
+ (BOOL)sa_swizzleClassMethod:(SEL)origSel_ withClassMethod:(SEL)altSel_ error:(NSError **)error_;

+ (BOOL)sa_swizzleMethod:(SEL)origSel_  withClass:(Class)altCla_ withMethod:(SEL)altSel_ error:(NSError **)error_;

@end

NS_ASSUME_NONNULL_END
