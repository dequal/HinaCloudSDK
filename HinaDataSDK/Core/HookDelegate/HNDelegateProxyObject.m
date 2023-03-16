//
// HNDelegateProxyObject.m
// HinaDataSDK
//
// Created by hina on 2022/11/12.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDelegateProxyObject.h"
#import <objc/message.h>

NSString * const kHNDelegateClassHinaSuffix = @"_CN.HINADATA";
NSString * const kHNDelegateClassKVOPrefix = @"KVONotifying_";

@implementation HNDelegateProxyObject

- (instancetype)initWithDelegate:(id)delegate proxy:(id)proxy {
    self = [super init];
    if (self) {
        _delegateProxy = proxy;

        _selectors = [NSMutableSet set];
        _delegateClass = [delegate class];

        Class cla = object_getClass(delegate);
        NSString *name = NSStringFromClass(cla);

        if ([name containsString:kHNDelegateClassKVOPrefix]) {
            _delegateIHN = class_getSuperclass(cla);
            _kvoClass = cla;
        } else if ([name containsString:kHNDelegateClassHinaSuffix]) {
            _delegateIHN = class_getSuperclass(cla);
            _hinaClassName = name;
        } else {
            _delegateIHN = cla;
            _hinaClassName = [NSString stringWithFormat:@"%@%@", name, kHNDelegateClassHinaSuffix];
        }
    }
    return self;
}

- (Class)hinaClass {
    return NSClassFromString(self.hinaClassName);
}

- (void)removeKVO {
    self.kvoClass = nil;
    self.hinaClassName = [NSString stringWithFormat:@"%@%@", self.delegateIHN, kHNDelegateClassHinaSuffix];
    [self.selectors removeAllObjects];
}

@end

#pragma mark - Utils

@implementation HNDelegateProxyObject (Utils)

/// 是不是 KVO 创建的类
/// @param cls 类
+ (BOOL)isKVOClass:(Class _Nullable)cls {
    return [NSStringFromClass(cls) containsString:kHNDelegateClassKVOPrefix];
}

@end

