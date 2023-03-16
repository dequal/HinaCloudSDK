//
// HNExceptionManager.m
// HinaDataSDK
//
// Created by hina on 2022/6/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNExceptionManager.h"
#import "HinaDataSDK.h"
#import "HinaDataSDK+Private.h"
#import "HNConstants+Private.h"
#import "HNModuleManager.h"
#import "HNLog.h"
#import "HNConfigOptions+Exception.h"

#include <libkern/OSAtomic.h>
#include <execinfo.h>

static NSString * const kHNSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
static NSString * const kHNSignalKey = @"UncaughtExceptionHandlerSignalKey";

static volatile int32_t kHNExceptionCount = 0;
static const int32_t kHNExceptionMaximum = 10;

static NSString * const kHNAppCrashedReason = @"app_crashed_reason";

@interface HNExceptionManager ()

@property (nonatomic) NSUncaughtExceptionHandler *defaultExceptionHandler;
@property (nonatomic, unsafe_unretained) struct sigaction *prev_signal_handlers;

@end

@implementation HNExceptionManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNExceptionManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNExceptionManager alloc] init];
    });
    return manager;
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        _prev_signal_handlers = calloc(NSIG, sizeof(struct sigaction));

        [self setupExceptionHandler];
    }
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    _configOptions = configOptions;
    self.enable = configOptions.enableTrackAppCrash;
}

- (void)dealloc {
    free(_prev_signal_handlers);
}

- (void)setupExceptionHandler {
    _defaultExceptionHandler = NSGetUncaughtExceptionHandler();
    NSSetUncaughtExceptionHandler(&HNHandleException);

    struct sigaction action;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_SIGINFO;
    action.sa_sigaction = &HNSignalHandler;
    int signals[] = {SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS};
    for (int i = 0; i < sizeof(signals) / sizeof(int); i++) {
        struct sigaction prev_action;
        int err = sigaction(signals[i], &action, &prev_action);
        if (err == 0) {
            char *address_action = (char *)&prev_action;
            char *address_signal = (char *)(_prev_signal_handlers + signals[i]);
            strlcpy(address_signal, address_action, sizeof(prev_action));
        } else {
            HNLogError(@"Errored while trying to set up sigaction for signal %d", signals[i]);
        }
    }
}

#pragma mark - Handler

static void HNSignalHandler(int crashSignal, struct __siginfo *info, void *context) {
    int32_t exceptionCount = OSAtomicIncrement32(&kHNExceptionCount);
    if (exceptionCount <= kHNExceptionMaximum) {
        NSDictionary *userInfo = @{kHNSignalKey: @(crashSignal)};
        NSString *reason = [NSString stringWithFormat:@"Signal %d was raised.", crashSignal];
        NSException *exception = [NSException exceptionWithName:kHNSignalExceptionName
                                                         reason:reason
                                                       userInfo:userInfo];

        [HNExceptionManager.defaultManager handleUncaughtException:exception];
    }

    struct sigaction prev_action = HNExceptionManager.defaultManager.prev_signal_handlers[crashSignal];
    if (prev_action.sa_flags & SA_SIGINFO) {
        if (prev_action.sa_sigaction) {
            prev_action.sa_sigaction(crashSignal, info, context);
        }
    } else if (prev_action.sa_handler &&
               prev_action.sa_handler != SIG_IGN) {
        // SIG_IGN 表示忽略信号
        prev_action.sa_handler(crashSignal);
    }
}

static void HNHandleException(NSException *exception) {
    int32_t exceptionCount = OSAtomicIncrement32(&kHNExceptionCount);
    if (exceptionCount <= kHNExceptionMaximum) {
        [HNExceptionManager.defaultManager handleUncaughtException:exception];
    }

    if (HNExceptionManager.defaultManager.defaultExceptionHandler) {
        HNExceptionManager.defaultManager.defaultExceptionHandler(exception);
    }
}

- (void)handleUncaughtException:(NSException *)exception {
    if (!self.enable) {
        return;
    }
    @try {
        NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
        if (exception.callStackSymbols) {
            properties[kHNAppCrashedReason] = [NSString stringWithFormat:@"Exception Reason:%@\nException Stack:%@", exception.reason, [exception.callStackSymbols componentsJoinedByString:@"\n"]];
        } else {
            properties[kHNAppCrashedReason] = [NSString stringWithFormat:@"%@ %@", exception.reason, [NSThread.callStackSymbols componentsJoinedByString:@"\n"]];
        }
        HNPresetEventObject *object = [[HNPresetEventObject alloc] initWithEventId:kHNEventNameAppCrashed];

        [HinaDataSDK.sharedInstance trackEventObject:object properties:properties];

        //触发页面浏览时长事件
        [[HNModuleManager sharedInstance] trackPageLeaveWhenCrashed];

        // 触发退出事件
        [HNModuleManager.sharedInstance trackAppEndWhenCrashed];

        // 阻塞当前线程，完成 serialQueue 中数据相关的任务
        hinadata_dispatch_safe_sync(HinaDataSDK.sdkInstance.serialQueue, ^{});
        HNLogError(@"Encountered an uncaught exception. All HinaData instances were archived.");
    } @catch(NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }

    NSSetUncaughtExceptionHandler(NULL);
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
}

@end
