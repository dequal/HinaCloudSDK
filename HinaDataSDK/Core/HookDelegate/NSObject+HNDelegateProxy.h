//
// NSObject+HNDelegateProxy.h
// HinaDataSDK
//
// Created by hina on 2022/11/5.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "HNDelegateProxyObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (DelegateProxy)

@property (nonatomic, copy, nullable) NSSet<NSString *> *hinadata_optionalSelectors;
@property (nonatomic, strong, nullable) HNDelegateProxyObject *hinadata_delegateObject;

/// hook respondsToSelector to resolve optional selectors
/// @param aSelector selector
- (BOOL)hinadata_respondsToSelector:(SEL)aSelector;

@end

@interface NSProxy (DelegateProxy)

@property (nonatomic, copy, nullable) NSSet<NSString *> *hinadata_optionalSelectors;
@property (nonatomic, strong, nullable) HNDelegateProxyObject *hinadata_delegateObject;

/// hook respondsToSelector to resolve optional selectors
/// @param aSelector selector
- (BOOL)hinadata_respondsToSelector:(SEL)aSelector;

@end

NS_ASSUME_NONNULL_END
