//
// HNDelegateProxy.m
// HinaDataSDK
//
// Created by hina on 2022/6/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HNHookDelegateProtocol <NSObject>
@optional
+ (NSSet<NSString *> *)optionalSelectors;

@end

@interface HNDelegateProxy : NSObject <HNHookDelegateProtocol>

/// proxy delegate with selectors
/// @param delegate delegate object, such as UITableViewDelegate、UICollectionViewDelegate, etc.
/// @param selectors delegate proxy methods, such as "tableView:didSelectRowAtIndexPath:"、"collectionView:didSelectItemAtIndexPath:", etc.
+ (void)proxyDelegate:(id)delegate selectors:(NSSet<NSString *>*)selectors;


/// forward selector with arguments
/// @param target target
/// @param selector selector
+ (void)invokeWithTarget:(NSObject *)target selector:(SEL)selector, ...;


/// actions for optional selectors
/// @param delegate delegate object
+ (void)resolveOptionalSelectorsForDelegate:(id)delegate;

@end

NS_ASSUME_NONNULL_END
