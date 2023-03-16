//
// HNDelegateProxy.m
// HinaDataSDK
//
// Created by hina on 2022/6/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDelegateProxy.h"
#import "HNClassHelper.h"
#import "HNMethodHelper.h"
#import "HNLog.h"
#import "NSObject+HNDelegateProxy.h"
#import <objc/message.h>

static NSString * const kHNNSObjectRemoveObserverSelector = @"removeObserver:forKeyPath:";
static NSString * const kHNNSObjectAddObserverSelector = @"addObserver:forKeyPath:options:context:";
static NSString * const kHNNSObjectClassSelector = @"class";

@implementation HNDelegateProxy

+ (void)proxyDelegate:(id)delegate selectors:(NSSet<NSString *> *)selectors {
    if (object_isClass(delegate) || selectors.count == 0) {
        return;
    }

    Class proxyClass = [self class];
    NSMutableSet *delegateSelectors = [NSMutableSet setWithSet:selectors];

    HNDelegateProxyObject *object = [delegate hinadata_delegateObject];
    if (!object) {
        object = [[HNDelegateProxyObject alloc] initWithDelegate:delegate proxy:proxyClass];
        [delegate setHinadata_delegateObject:object];
    }

    [delegateSelectors minusSet:object.selectors];
    if (delegateSelectors.count == 0) {
        return;
    }

    if (object.hinaClass) {
        [self addInstanceMethodWithSelectors:delegateSelectors fromClass:proxyClass toClass:object.hinaClass];
        [object.selectors unionSet:delegateSelectors];

        // 代理对象未继承自海纳类, 需要重置代理对象的 isa 为海纳类
        if (![object_getClass(delegate) isSubclassOfClass:object.hinaClass]) {
            [HNClassHelper setObject:delegate toClass:object.hinaClass];
        }
        return;
    }

    if (object.kvoClass) {
        // 在移除所有的 KVO 属性监听时, 系统会重置对象的 isa 指针为原有的类;
        // 因此需要在移除监听时, 重新为代理对象设置新的子类, 来采集点击事件.
        if ([delegate isKindOfClass:NSObject.class] && ![object.selectors containsObject:kHNNSObjectRemoveObserverSelector]) {
            [delegateSelectors addObject:kHNNSObjectRemoveObserverSelector];
        }
        [self addInstanceMethodWithSelectors:delegateSelectors fromClass:proxyClass toClass:object.kvoClass];
        [object.selectors unionSet:delegateSelectors];
        return;
    }

    Class hinaClass = [HNClassHelper allocateClassWithObject:delegate className:object.hinaClassName];
    [HNClassHelper registerClass:hinaClass];

    // 新建子类后, 需要监听是否添加了 KVO, 因为添加 KVO 属性监听后,
    // KVO 会重写 Class 方法, 导致获取的 Class 为海纳添加的子类
    if ([delegate isKindOfClass:NSObject.class] && ![object.selectors containsObject:kHNNSObjectAddObserverSelector]) {
        [delegateSelectors addObject:kHNNSObjectAddObserverSelector];
    }

    // 重写 Class 方法
    if (![object.selectors containsObject:kHNNSObjectClassSelector]) {
        [delegateSelectors addObject:kHNNSObjectClassSelector];
    }

    [self addInstanceMethodWithSelectors:delegateSelectors fromClass:proxyClass toClass:hinaClass];
    [object.selectors unionSet:delegateSelectors];

    [HNClassHelper setObject:delegate toClass:hinaClass];
}

+ (void)addInstanceMethodWithSelectors:(NSSet<NSString *> *)selectors fromClass:(Class)fromClass toClass:(Class)toClass {
    for (NSString *selector in selectors) {
        SEL sel = NSSelectorFromString(selector);
        [HNMethodHelper addInstanceMethodWithSelector:sel fromClass:fromClass toClass:toClass];
    }
}

+ (void)invokeWithTarget:(NSObject *)target selector:(SEL)selector, ... {
    Class originalClass = target.hinadata_delegateObject.delegateIHN;

    va_list args;
    va_start(args, selector);
    id arg1 = nil, arg2 = nil, arg3 = nil, arg4 = nil;
    NSInteger count = [NSStringFromSelector(selector) componentsSeparatedByString:@":"].count - 1;
    for (NSInteger i = 0; i < count; i++) {
        i == 0 ? (arg1 = va_arg(args, id)) : nil;
        i == 1 ? (arg2 = va_arg(args, id)) : nil;
        i == 2 ? (arg3 = va_arg(args, id)) : nil;
        i == 3 ? (arg4 = va_arg(args, id)) : nil;
    }
    struct objc_super targetSuper = {
        .receiver = target,
        .super_class = originalClass
    };
    // 消息转发给原始类
    @try {
        void (*func)(struct objc_super *, SEL, id, id, id, id) = (void *)&objc_msgSendSuper;
        func(&targetSuper, selector, arg1, arg2, arg3, arg4);
    } @catch (NSException *exception) {
        HNLogInfo(@"msgSendSuper with exception: %@", exception);
    } @finally {
        va_end(args);
    }
}

+ (void)resolveOptionalSelectorsForDelegate:(id)delegate {
    if (object_isClass(delegate)) {
        return;
    }

    NSSet *currentOptionalSelectors = ((NSObject *)delegate).hinadata_optionalSelectors;
    NSMutableSet *optionalSelectors = [[NSMutableSet alloc] init];
    if (currentOptionalSelectors) {
        [optionalSelectors unionSet:currentOptionalSelectors];
    }
    
    if ([self respondsToSelector:@selector(optionalSelectors)] &&[self optionalSelectors]) {
        [optionalSelectors unionSet:[self optionalSelectors]];
    }
    ((NSObject *)delegate).hinadata_optionalSelectors = [optionalSelectors copy];
}

@end

#pragma mark - Class
@implementation HNDelegateProxy (Class)

- (Class)class {
    if (self.hinadata_delegateObject.delegateClass) {
        return self.hinadata_delegateObject.delegateClass;
    }
    return [super class];
}

@end

#pragma mark - KVO
@implementation HNDelegateProxy (KVO)

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    [super addObserver:observer forKeyPath:keyPath options:options context:context];
    if (self.hinadata_delegateObject) {
        // 由于添加了 KVO 属性监听, KVO 会创建子类并重写 Class 方法,返回原始类; 此时的原始类为海纳添加的子类,因此需要重写 class 方法
        [HNMethodHelper replaceInstanceMethodWithDestinationSelector:@selector(class) sourceSelector:@selector(class) fromClass:HNDelegateProxy.class toClass:object_getClass(self)];
    }
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    // remove 前代理对象是否归属于 KVO 创建的类
    BOOL oldClassIsKVO = [HNDelegateProxyObject isKVOClass:object_getClass(self)];
    [super removeObserver:observer forKeyPath:keyPath];
    // remove 后代理对象是否归属于 KVO 创建的类
    BOOL newClassIsKVO = [HNDelegateProxyObject isKVOClass:object_getClass(self)];
    
    // 有多个属性监听时, 在最后一个监听被移除后, 对象的 isa 发生变化, 需要重新为代理对象添加子类
    if (oldClassIsKVO && !newClassIsKVO) {
        Class delegateProxy = self.hinadata_delegateObject.delegateProxy;
        NSSet *selectors = [self.hinadata_delegateObject.selectors copy];

        [self.hinadata_delegateObject removeKVO];
        if ([delegateProxy respondsToSelector:@selector(proxyDelegate:selectors:)]) {
            [delegateProxy proxyDelegate:self selectors:selectors];
        }
    }
}

@end
