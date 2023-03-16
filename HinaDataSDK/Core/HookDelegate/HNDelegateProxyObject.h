//
// HNDelegateProxyObject.h
// HinaDataSDK
//
// Created by hina on 2022/11/12.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNDelegateProxyObject : NSObject

@property (nonatomic, strong) Class delegateIHN;
@property (nonatomic, strong, nullable) Class kvoClass;

@property (nonatomic, copy, nullable) NSString *hinaClassName;
@property (nonatomic, strong, readonly, nullable) Class hinaClass;

/// 记录 - class 方法的返回值
@property (nonatomic, strong) id delegateClass;

/// 移除 KVO 后, 重新 hook 时使用的 Proxy
@property (nonatomic, strong) Class delegateProxy;

/// 当前代理对象已 hook 的方法集合
@property (nonatomic, strong) NSMutableSet *selectors;

- (instancetype)initWithDelegate:(id)delegate proxy:(id)proxy;

- (void)removeKVO;

@end

@interface HNDelegateProxyObject (Utils)

+ (BOOL)isKVOClass:(Class _Nullable)cls;

@end

NS_ASSUME_NONNULL_END
