// NSInvocation+HNHelpers.h
// HinaDataSDK
//
// Created by hina on 1/20/16
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

@interface NSInvocation (HNHelpers)

- (void)sa_setArgumentsFromArray:(NSArray *)argumentArray;
- (id)sa_returnValue;

@end
