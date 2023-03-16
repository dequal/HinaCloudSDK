//
// NSObject+HNCellClick.m
// HinaDataSDK
//
// Created by hina on 2022/11/5.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "NSObject+HNDelegateProxy.h"
#import <objc/runtime.h>

static void *const kHNNSObjectDelegateOptionalSelectorsKey = (void *)&kHNNSObjectDelegateOptionalSelectorsKey;
static void *const kHNNSObjectDelegateObjectKey = (void *)&kHNNSObjectDelegateObjectKey;

static void *const kHNNSProxyDelegateOptionalSelectorsKey = (void *)&kHNNSProxyDelegateOptionalSelectorsKey;
static void *const kHNNSProxyDelegateObjectKey = (void *)&kHNNSProxyDelegateObjectKey;

@implementation NSObject (DelegateProxy)

- (NSSet<NSString *> *)hinadata_optionalSelectors {
    return objc_getAssociatedObject(self, kHNNSObjectDelegateOptionalSelectorsKey);
}

- (void)setHinadata_optionalSelectors:(NSSet<NSString *> *)hinadata_optionalSelectors {
    objc_setAssociatedObject(self, kHNNSObjectDelegateOptionalSelectorsKey, hinadata_optionalSelectors, OBJC_ASSOCIATION_COPY);
}

- (HNDelegateProxyObject *)hinadata_delegateObject {
    return objc_getAssociatedObject(self, kHNNSObjectDelegateObjectKey);
}

- (void)setHinadata_delegateObject:(HNDelegateProxyObject *)hinadata_delegateObject {
    objc_setAssociatedObject(self, kHNNSObjectDelegateObjectKey, hinadata_delegateObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)hinadata_respondsToSelector:(SEL)aSelector {
    if ([self hinadata_respondsToSelector:aSelector]) {
        return YES;
    }
    if ([self.hinadata_optionalSelectors containsObject:NSStringFromSelector(aSelector)]) {
        return YES;
    }
    return NO;
}

@end

@implementation NSProxy (DelegateProxy)

- (NSSet<NSString *> *)hinadata_optionalSelectors {
    return objc_getAssociatedObject(self, kHNNSProxyDelegateOptionalSelectorsKey);
}

- (void)setHinadata_optionalSelectors:(NSSet<NSString *> *)hinadata_optionalSelectors {
    objc_setAssociatedObject(self, kHNNSProxyDelegateOptionalSelectorsKey, hinadata_optionalSelectors, OBJC_ASSOCIATION_COPY);
}

- (HNDelegateProxyObject *)hinadata_delegateObject {
    return objc_getAssociatedObject(self, kHNNSProxyDelegateObjectKey);
}

- (void)setHinadata_delegateObject:(HNDelegateProxyObject *)hinadata_delegateObject {
    objc_setAssociatedObject(self, kHNNSProxyDelegateObjectKey, hinadata_delegateObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)hinadata_respondsToSelector:(SEL)aSelector {
    if ([self hinadata_respondsToSelector:aSelector]) {
        return YES;
    }
    if ([self.hinadata_optionalSelectors containsObject:NSStringFromSelector(aSelector)]) {
        return YES;
    }
    return NO;
}

@end
