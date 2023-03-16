//
// HNAppLifecycle.h
// HinaDataSDK
//
// Created by hina on 2022/4/1.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNModuleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// SDK 生命周期状态
typedef NS_ENUM(NSUInteger, HNAppLifecycleState) {
    HNAppLifecycleStateInit = 1,
    HNAppLifecycleStateStart,
    HNAppLifecycleStateStartPassively,
    HNAppLifecycleStateEnd,
    HNAppLifecycleStateTerminate,
};

/// 当生命周期状态即将改变时，会发送这个通知
/// object：对象为当前的生命周期对象
/// userInfo：包含 kHNAppLifecycleNewStateKey 和 kHNAppLifecycleOldStateKey 两个 key，分别对应状态改变的前后状态
extern NSNotificationName const kHNAppLifecycleStateWillChangeNotification;
/// 当生命周期状态改变后，会发送这个通知
/// object：对象为当前的生命周期对象
/// userInfo：包含 kHNAppLifecycleNewStateKey 和 kHNAppLifecycleOldStateKey 两个 key，分别对应状态改变的前后状态
extern NSNotificationName const kHNAppLifecycleStateDidChangeNotification;
/// 在状态改变通知回调中，获取新状态
extern NSString * const kHNAppLifecycleNewStateKey;
/// 在状态改变通知回调中，获取之前的状态
extern NSString * const kHNAppLifecycleOldStateKey;

@interface HNAppLifecycle : NSObject

@property (nonatomic, assign, readonly) HNAppLifecycleState state;

@end

NS_ASSUME_NONNULL_END
