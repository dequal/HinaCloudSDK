//
// HNAutoTrackManager.m
// HinaDataSDK
//
// Created by hina on 2022/4/2.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAutoTrackManager.h"
#import "HNConfigOptions.h"
#import "HNRemoteConfigModel.h"
#import "HNModuleManager.h"
#import "HNAppLifecycle.h"
#import "HNLog.h"
#import "UIApplication+HNAutoTrack.h"
#import "UIViewController+HNAutoTrack.h"
#import "HNSwizzle.h"
#import "HNAppStartTracker.h"
#import "HNAppEndTracker.h"
#import "HNConstants+Private.h"
#import "UIGestureRecognizer+HNAutoTrack.h"
#import "HNGestureViewProcessorFactory.h"
#import "HNCommonUtility.h"
#import "HNApplication.h"
#import "HinaDataSDK+HNAutoTrack.h"
#import "UIViewController+HNPageLeave.h"

//event tracker plugins
#if __has_include("HNCellClickHookDelegatePlugin.h")
#import "HNCellClickHookDelegatePlugin.h"
#endif
#import "HNCellClickDynamicSubclassPlugin.h"
#import "HNEventTrackerPluginManager.h"
#if __has_include("HNGesturePlugin.h")
#import "HNGesturePlugin.h"
#endif

@interface HNAutoTrackManager ()

@property (nonatomic, strong) HNAppStartTracker *appStartTracker;
@property (nonatomic, strong) HNAppEndTracker *appEndTracker;

@property (nonatomic, getter=isDisableSDK) BOOL disableSDK;
@property (nonatomic, assign) NSInteger autoTrackMode;

@end

@implementation HNAutoTrackManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNAutoTrackManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNAutoTrackManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _appStartTracker = [[HNAppStartTracker alloc] init];
        _appEndTracker = [[HNAppEndTracker alloc] init];
        _appViewScreenTracker = [[HNAppViewScreenTracker alloc] init];
        _appClickTracker = [[HNAppClickTracker alloc] init];
        _appPageLeaveTracker = [[HNAppPageLeaveTracker alloc] init];

        _disableSDK = NO;
        _autoTrackMode = kHNAutoTrackModeDefault;
        [self updateAutoTrackEventType];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLifecycleStateDidChange:) name:kHNAppLifecycleStateDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remoteConfigModelChanged:) name:HN_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION object:nil];
    }
    return self;
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    if ([HNApplication isAppExtension]) {
        configOptions.enableAutoTrack = NO;
    }
    _configOptions = configOptions;
    self.enable = configOptions.enableAutoTrack;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        [self enableAutoTrack];
        [self registerPlugins];
        return;
    }
    [self.appPageLeaveTracker.pageLeaveObjects removeAllObjects];
    [self unregisterPlugins];
}

#pragma mark - HNAutoTrackModuleProtocol

- (void)trackAppEndWhenCrashed {
    if (!self.enable) {
        return;
    }
    if (self.appEndTracker.isIgnored) {
        return;
    }
    [HNCommonUtility performBlockOnMainThread:^{
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            [self.appEndTracker autoTrackEvent];
        }
    }];
}

- (void)trackPageLeaveWhenCrashed {
    if (!self.enable) {
        return;
    }
    if (!self.configOptions.enableTrackPageLeave) {
        return;
    }
    [HNCommonUtility performBlockOnMainThread:^{
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            [self.appPageLeaveTracker trackEvents];
        }
    }];
}

#pragma mark - Notification

- (void)appLifecycleStateDidChange:(NSNotification *)sender {
    if (!self.enable) {
        return;
    }
    NSDictionary *userInfo = sender.userInfo;
    HNAppLifecycleState newState = [userInfo[kHNAppLifecycleNewStateKey] integerValue];
    HNAppLifecycleState oldState = [userInfo[kHNAppLifecycleOldStateKey] integerValue];

    self.appStartTracker.passively = NO;
    self.appViewScreenTracker.passively = NO;

    // 被动启动
    if (oldState == HNAppLifecycleStateInit && newState == HNAppLifecycleStateStartPassively) {
        self.appStartTracker.passively = YES;
        self.appViewScreenTracker.passively = YES;
        
        [self.appStartTracker autoTrackEventWithProperties:HNModuleManager.sharedInstance.utmProperties];
        return;
    }

    // 冷（热）启动
    if (newState == HNAppLifecycleStateStart) {
        // 启动 AppEnd 事件计时器
        [self.appEndTracker trackTimerStartAppEnd];
        // 触发启动事件
        [self.appStartTracker autoTrackEventWithProperties:HNModuleManager.sharedInstance.utmProperties];
        // 热启动时触发被动启动的页面浏览事件
        if (oldState == HNAppLifecycleStateStartPassively) {
            [self.appViewScreenTracker trackEventOfLaunchedPassively];
        }
        return;
    }

    // 退出
    if (newState == HNAppLifecycleStateEnd) {
        [self.appEndTracker autoTrackEvent];
    }
}

- (void)remoteConfigModelChanged:(NSNotification *)sender {
    @try {
        self.disableSDK = [[sender.object valueForKey:@"disableSDK"] boolValue];
        self.autoTrackMode = [[sender.object valueForKey:@"autoTrackMode"] integerValue];

        [self updateAutoTrackEventType];
    } @catch(NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
}

#pragma mark - Public

- (BOOL)isAutoTrackEnabled {
    if (self.isDisableSDK) {
        HNLogDebug(@"SDK is disabled");
        return NO;
    }

    NSInteger autoTrackMode = self.autoTrackMode;
    if (autoTrackMode == kHNAutoTrackModeDefault) {
        // 远程配置不修改现有的 autoTrack 方式
        return (self.configOptions.autoTrackEventType != HinaDataEventTypeNone);
    } else {
        // 远程配置修改现有的 autoTrack 方式
        BOOL isEnabled = (autoTrackMode != kHNAutoTrackModeDisabledAll);
        if (!isEnabled) {
            HNLogDebug(@"【remote config】AutoTrack Event is ignored by remote config");
        }
        return isEnabled;
    }
}

- (BOOL)isAutoTrackEventTypeIgnored:(HinaDataAutoTrackEventType)eventType {
    if (self.isDisableSDK) {
        HNLogDebug(@"SDK is disabled");
        return YES;
    }

    NSInteger autoTrackMode = self.autoTrackMode;
    if (autoTrackMode == kHNAutoTrackModeDefault) {
        // 远程配置不修改现有的 autoTrack 方式
        return !(self.configOptions.autoTrackEventType & eventType);
    } else {
        // 远程配置修改现有的 autoTrack 方式
        BOOL isIgnored = (autoTrackMode == kHNAutoTrackModeDisabledAll) ? YES : !(autoTrackMode & eventType);
        if (isIgnored) {
            NSString *ignoredEvent = @"None";
            switch (eventType) {
                case HinaDataEventTypeAppStart:
                    ignoredEvent = kHNEventNameAppStart;
                    break;

                case HinaDataEventTypeAppEnd:
                    ignoredEvent = kHNEventNameAppEnd;
                    break;

                case HinaDataEventTypeAppClick:
                    ignoredEvent = kHNEventNameAppClick;
                    break;

                case HinaDataEventTypeAppViewScreen:
                    ignoredEvent = kHNEventNameAppViewScreen;
                    break;

                default:
                    break;
            }
            HNLogDebug(@"【remote config】%@ is ignored by remote config", ignoredEvent);
        }
        return isIgnored;
    }
}

- (void)updateAutoTrackEventType {
    self.appStartTracker.ignored = [self isAutoTrackEventTypeIgnored:HinaDataEventTypeAppStart];
    self.appEndTracker.ignored = [self isAutoTrackEventTypeIgnored:HinaDataEventTypeAppEnd];
    self.appViewScreenTracker.ignored = [self isAutoTrackEventTypeIgnored:HinaDataEventTypeAppViewScreen];
    self.appClickTracker.ignored = [self isAutoTrackEventTypeIgnored:HinaDataEventTypeAppClick];
}

- (BOOL)isGestureVisualView:(id)obj {
    if (!self.enable) {
        return NO;
    }
    if (![obj isKindOfClass:UIView.class]) {
        return NO;
    }
    UIView *view = (UIView *)obj;
    for (UIGestureRecognizer *gesture in view.gestureRecognizers) {
        if (gesture.hinadata_gestureTarget) {
            HNGeneralGestureViewProcessor *processor = [HNGestureViewProcessorFactory processorWithGesture:gesture];
            if (processor.isTrackable && processor.trackableView == gesture.view) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark – Private Methods

- (void)enableAutoTrack {
    // 监听所有 UIViewController 显示事件
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self enableAppViewScreenAutoTrack];
        [self enableAppClickAutoTrack];
        [self enableAppPageLeave];
    });
}

- (void)enableAppViewScreenAutoTrack {
    [UIViewController sa_swizzleMethod:@selector(viewDidAppear:)
                            withMethod:@selector(sa_autotrack_viewDidAppear:)
                                 error:NULL];
}

- (void)enableAppClickAutoTrack {
    // Actions & Events
    NSError *error = NULL;
    [UIApplication sa_swizzleMethod:@selector(sendAction:to:from:forEvent:)
                         withMethod:@selector(sa_sendAction:to:from:forEvent:)
                              error:&error];
    if (error) {
        HNLogError(@"Failed to swizzle sendAction:to:forEvent: on UIAppplication. Details: %@", error);
        error = NULL;
    }
}

- (void)enableAppPageLeave {
    if (!self.configOptions.enableTrackPageLeave) {
        return;
    }
    [UIViewController sa_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(hinadata_pageLeave_viewDidAppear:) error:NULL];
    [UIViewController sa_swizzleMethod:@selector(viewDidDisappear:) withMethod:@selector(hinadata_pageLeave_viewDidDisappear:) error:NULL];
}

- (void)registerPlugins {
    BOOL enableAppClick = self.configOptions.autoTrackEventType & HinaDataEventTypeAppClick;
    if (!enableAppClick) {
        return;
    }
    //UITableView/UICollectionView Cell + AppClick plugin register
#if __has_include("HNCellClickHookDelegatePlugin.h")
    [[HNEventTrackerPluginManager defaultManager] registerPlugin:[[HNCellClickHookDelegatePlugin alloc] init]];
#else
    [[HNEventTrackerPluginManager defaultManager] registerPlugin:[[HNCellClickDynamicSubclassPlugin alloc] init]];
#endif

    //UIGestureRecognizer + AppClick plugin register
#if __has_include("HNGesturePlugin.h")
    [[HNEventTrackerPluginManager defaultManager] registerPlugin:[[HNGesturePlugin alloc] init]];
#endif
}

- (void)unregisterPlugins {
    //unregister UITableView/UICollectionView cell click plugin
#if __has_include("HNCellClickHookDelegatePlugin.h")
    [[HNEventTrackerPluginManager defaultManager] unregisterPlugin:[HNCellClickHookDelegatePlugin class]];
#else
    [[HNEventTrackerPluginManager defaultManager] unregisterPlugin:[HNCellClickDynamicSubclassPlugin class]];
#endif

    //unregister HNGesturePlugin
#if __has_include("HNGesturePlugin.h")
    [[HNEventTrackerPluginManager defaultManager] unregisterPlugin:[HNGesturePlugin class]];
#endif
}

@end

