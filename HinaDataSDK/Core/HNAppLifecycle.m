//
// HNAppLifecycle.m
// HinaDataSDK
//
// Created by hina on 2022/4/1.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAppLifecycle.h"
#import "HNLog.h"
#import "HNApplication.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

NSNotificationName const kHNAppLifecycleStateWillChangeNotification = @"com.hinadata.HNAppLifecycleStateWillChange";
NSNotificationName const kHNAppLifecycleStateDidChangeNotification = @"com.hinadata.HNAppLifecycleStateDidChange";
NSString * const kHNAppLifecycleNewStateKey = @"new";
NSString * const kHNAppLifecycleOldStateKey = @"old";

@interface HNAppLifecycle ()

@property (nonatomic, assign) HNAppLifecycleState state;

@end

@implementation HNAppLifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _state = HNAppLifecycleStateInit;

        [self setupListeners];
        [self setupLaunchedState];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupLaunchedState {
    if ([HNApplication isAppExtension]) {
        return;
    }
    dispatch_block_t mainThreadBlock = ^(){
#if TARGET_OS_IOS
        UIApplication *application = [HNApplication sharedApplication];
        BOOL isAppStateBackground = application.applicationState == UIApplicationStateBackground;
#else
        BOOL isAppStateBackground = NO;
#endif
        self.state = isAppStateBackground ? HNAppLifecycleStateStartPassively : HNAppLifecycleStateStart;
    };

    if (@available(iOS 13.0, *)) {
        // iOS 13 及以上在异步主队列的 block 修改状态的原因:
        // 1. 保证在执行启动（被动启动）事件时（动态）公共属性设置完毕（通过监听 UIApplicationDidFinishLaunchingNotification 可以实现）
        // 2. 含有 SceneDelegate 的工程中延迟获取 applicationState 才是准确的（通过监听 UIApplicationDidFinishLaunchingNotification 获取不准确）
        dispatch_async(dispatch_get_main_queue(), mainThreadBlock);
    } else {
        // iOS 13 以下通过监听 UIApplicationDidFinishLaunchingNotification 的通知来处理被动启动和冷启动（非延迟初始化）的情况:
        // 1. iOS 13 以下被动启动时异步主队列的 block 不会执行
        // 2. iOS 13 以下不会含有 SceneDelegate
#if TARGET_OS_IOS
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidFinishLaunching:)
                                                     name:UIApplicationDidFinishLaunchingNotification
                                                   object:nil];
#endif
        // 处理 iOS 13 以下（冷启动）延迟初始化的情况
        dispatch_async(dispatch_get_main_queue(), mainThreadBlock);
    }
}

#pragma mark - Setter

- (void)setState:(HNAppLifecycleState)state {
    if (_state == state) {
        return;
    }

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithCapacity:2];
    userInfo[kHNAppLifecycleNewStateKey] = @(state);
    userInfo[kHNAppLifecycleOldStateKey] = @(_state);

    [[NSNotificationCenter defaultCenter] postNotificationName:kHNAppLifecycleStateWillChangeNotification object:self userInfo:userInfo];

    _state = state;

    [[NSNotificationCenter defaultCenter] postNotificationName:kHNAppLifecycleStateDidChangeNotification object:self userInfo:userInfo];
}

#pragma mark - Listener

- (void)setupListeners {
    // app extension does not need state observer
    if ([HNApplication isAppExtension]) {
        return;
    }

    // 监听 App 启动或结束事件
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
#if TARGET_OS_IOS
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                        object:nil];

#elif TARGET_OS_OSX

    [notificationCenter addObserver:self
                           selector:@selector(applicationDidFinishLaunching:)
                               name:NSApplicationDidFinishLaunchingNotification
                             object:nil];

    // 聚焦活动状态，和其他 App 之前切换聚焦，和 DidResignActive 通知会频繁调用
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:NSApplicationDidBecomeActiveNotification
                             object:nil];
    // 失焦状态
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidResignActive:)
                               name:NSApplicationDidResignActiveNotification
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:NSApplicationWillTerminateNotification
                             object:nil];
#endif
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    HNLogDebug(@"application did finish launching");

#if TARGET_OS_IOS
    UIApplication *application = [HNApplication sharedApplication];
    BOOL isAppStateBackground = application.applicationState == UIApplicationStateBackground;
    self.state = isAppStateBackground ? HNAppLifecycleStateStartPassively : HNAppLifecycleStateStart;
#else
    self.state = HNAppLifecycleStateStart;
#endif
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    HNLogDebug(@"application did become active");

#if TARGET_OS_IOS
    // 防止主动触发 UIApplicationDidBecomeActiveNotification
    if (![notification.object isKindOfClass:[UIApplication class]]) {
        return;
    }

    UIApplication *application = (UIApplication *)notification.object;
    if (application.applicationState != UIApplicationStateActive) {
        return;
    }
#elif TARGET_OS_OSX
    if (![notification.object isKindOfClass:[NSApplication class]]) {
        return;
    }

    NSApplication *application = (NSApplication *)notification.object;
    if (!application.isActive) {
        return;
    }
#endif

    self.state = HNAppLifecycleStateStart;
}

#if TARGET_OS_IOS
- (void)applicationDidEnterBackground:(NSNotification *)notification {
    HNLogDebug(@"application did enter background");

    // 防止主动触发 UIApplicationDidEnterBackgroundNotification
    if (![notification.object isKindOfClass:[UIApplication class]]) {
        return;
    }

    UIApplication *application = (UIApplication *)notification.object;
    if (application.applicationState != UIApplicationStateBackground) {
        return;
    }

    self.state = HNAppLifecycleStateEnd;
}

#elif TARGET_OS_OSX
- (void)applicationDidResignActive:(NSNotification *)notification {
    HNLogDebug(@"application did resignActive");

    if (![notification.object isKindOfClass:[NSApplication class]]) {
        return;
    }

    NSApplication *application = (NSApplication *)notification.object;
    if (application.isActive) {
        return;
    }
    self.state = HNAppLifecycleStateEnd;
}
#endif

- (void)applicationWillTerminate:(NSNotification *)notification {
    HNLogDebug(@"applicationWillTerminateNotification");

    self.state = HNAppLifecycleStateTerminate;
}

@end

