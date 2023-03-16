//
// HNRemoteConfigCheckOperator.m
// HinaDataSDK
//
// Created by hina on 2022/11/1.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNRemoteConfigCheckOperator.h"
#import "HNConstants+Private.h"
#import "HNURLUtils.h"
#import "HNAlertController.h"
#import "HNCommonUtility.h"
#import "HNReachability.h"
#import "HNLog.h"

typedef void (^ HNRemoteConfigCheckAlertHandler)(HNAlertAction *action);

@interface HNRemoteConfigCheckAlertModel : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *defaultStyleTitle;
@property (nonatomic, copy) HNRemoteConfigCheckAlertHandler defaultStyleHandler;
@property (nonatomic, copy) NSString *cancelStyleTitle;
@property (nonatomic, copy) HNRemoteConfigCheckAlertHandler cancelStyleHandler;

@end

@implementation HNRemoteConfigCheckAlertModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _title = HNLocalizedString(@"HNAlertHint");
        _message = nil;
        _defaultStyleTitle = HNLocalizedString(@"HNAlertOK");
        _defaultStyleHandler = nil;
        _cancelStyleTitle = nil;
        _cancelStyleHandler = nil;
    }
    return self;
}

@end

@interface HNRemoteConfigCheckOperator ()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) UIActivityIndicatorView *indicator;

@end

@implementation HNRemoteConfigCheckOperator

#pragma mark - Protocol

- (BOOL)handleRemoteConfigURL:(NSURL *)url {
    HNLogDebug(@"【remote config】The input QR url is: %@", url);
    
    if (![HNReachability sharedInstance].isReachable) {
        [self showNetworkErrorAlert];
        return NO;
    }
    
    NSDictionary *components = [HNURLUtils queryItemsWithURL:url];
    if (!components) {
        HNLogError(@"【remote config】The QR url format is invalid");
        return NO;
    }
    
    NSString *urlProject = components[@"project"] ?: @"default";
    NSString *urlOS = components[@"os"];
    NSString *urlAppID = components[@"app_id"];
    NSString *urlVersion = components[@"nv"];
    HNLogDebug(@"【remote config】The input QR url project is %@, os is %@, app_id is %@", urlProject, urlOS, urlAppID);
    
    NSString *currentProject = self.project ?: @"default";
    NSString *currentOS = @"iOS";
    NSString *currentAppID = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    HNLogDebug(@"【remote config】The current project is %@, os is %@, app_id is %@", currentProject, currentOS, currentAppID);
    
    BOOL isCheckPassed = NO;
    NSString *message = nil;
    if (![urlProject isEqualToString:currentProject]) {
        message = HNLocalizedString(@"HNRemoteConfigProjectError");
    } else if (![urlOS isEqualToString:currentOS]) {
        message = HNLocalizedString(@"HNRemoteConfigOSError");
    } else if (![urlAppID isEqualToString:currentAppID]) {
        message = HNLocalizedString(@"HNRemoteConfigAppError");
    } else if (!urlVersion) {
        message = HNLocalizedString(@"HNRemoteConfigQRError");
    } else {
        isCheckPassed = YES;
        message = HNLocalizedString(@"HNRemoteConfigStart");
    }
    [self showURLCheckAlertWithMessage:message isCheckPassed:isCheckPassed urlVersion:urlVersion];

    return YES;
}

#pragma mark - Private

#pragma mark Alert

- (void)showNetworkErrorAlert {
    HNRemoteConfigCheckAlertModel *model = [[HNRemoteConfigCheckAlertModel alloc] init];
    model.message = HNLocalizedString(@"HNRemoteConfigNetworkError");
    [self showAlertWithModel:model];
}

- (void)showURLCheckAlertWithMessage:(NSString *)message isCheckPassed:(BOOL)isCheckPassed urlVersion:(NSString *)urlVersion {
    HNRemoteConfigCheckAlertModel *model = [[HNRemoteConfigCheckAlertModel alloc] init];
    model.message = message;
    if (isCheckPassed) {
        model.defaultStyleTitle = HNLocalizedString(@"HNAlertContinue");
        __weak typeof(self) weakSelf = self;
        model.defaultStyleHandler = ^(HNAlertAction *action) {
            __strong typeof(weakSelf) strongSelf = weakSelf;

            [strongSelf requestRemoteConfigWithURLVersion:urlVersion];
        };
        model.cancelStyleTitle = HNLocalizedString(@"HNAlertCancel");
    }
    [self showAlertWithModel:model];
}

- (void)showRequestRemoteConfigFailedAlert {
    HNRemoteConfigCheckAlertModel *model = [[HNRemoteConfigCheckAlertModel alloc] init];
    model.message = HNLocalizedString(@"HNRemoteConfigObtainFailed");
    [self showAlertWithModel:model];
}

- (void)showVersionCheckAlertWithCurrentVersion:(nullable NSString *)currentVersion urlVersion:(NSString *)urlVersion {
    BOOL isEqual = [currentVersion isEqualToString:urlVersion];
    
    HNRemoteConfigCheckAlertModel *model = [[HNRemoteConfigCheckAlertModel alloc] init];
    model.title = isEqual ? HNLocalizedString(@"HNAlertHint") : HNLocalizedString(@"HNRemoteConfigWrongVersion");
    model.message = isEqual ? HNLocalizedString(@"HNRemoteConfigLoaded") : [NSString stringWithFormat:HNLocalizedString(@"HNRemoteConfigCompareVersion"), currentVersion, urlVersion];
    [self showAlertWithModel:model];
}

- (void)showAlertWithModel:(HNRemoteConfigCheckAlertModel *)model {
    [HNCommonUtility performBlockOnMainThread:^{
        HNAlertController *alertController = [[HNAlertController alloc] initWithTitle:model.title message:model.message preferredStyle:HNAlertControllerStyleAlert];
        [alertController addActionWithTitle:model.defaultStyleTitle style:HNAlertActionStyleDefault handler:model.defaultStyleHandler];
        if (model.cancelStyleTitle) {
            [alertController addActionWithTitle:model.cancelStyleTitle style:HNAlertActionStyleCancel handler:model.cancelStyleHandler];
        }
        [alertController show];
    }];
}

#pragma mark Request

- (void)requestRemoteConfigWithURLVersion:(NSString *)urlVersion {
    [self showIndicator];

    __weak typeof(self) weakSelf = self;
    [self requestRemoteConfigWithForceUpdate:YES completion:^(BOOL success, NSDictionary<NSString *,id> * _Nullable config) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf hideIndicator];
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                HNLogDebug(@"【remote config】The request result: success is %d, config is %@", success, config);

                if (success && config) {
                    // 远程配置
                    NSDictionary<NSString *, id> *remoteConfig = [strongSelf extractRemoteConfig:config];
                    [strongSelf handleRemoteConfig:remoteConfig withURLVersion:urlVersion];
                } else {
                    [strongSelf showRequestRemoteConfigFailedAlert];
                }
            } @catch (NSException *exception) {
                HNLogError(@"【remote config】%@ error: %@", strongSelf, exception);
            }
        });
    }];
}

- (void)handleRemoteConfig:(NSDictionary<NSString *, id> *)remoteConfig withURLVersion:(NSString *)urlVersion {
    NSString *currentVersion = remoteConfig[@"configs"][@"nv"];

    [self showVersionCheckAlertWithCurrentVersion:currentVersion urlVersion:urlVersion];

    if (![currentVersion isEqualToString:urlVersion]) {
        return;
    }

    NSMutableDictionary<NSString *, id> *eventMDic = [NSMutableDictionary dictionaryWithDictionary:remoteConfig];
    eventMDic[@"debug"] = @YES;
    [self trackAppRemoteConfigChanged:eventMDic];

    NSMutableDictionary<NSString *, id> *enableMDic = [NSMutableDictionary dictionaryWithDictionary:remoteConfig];
    enableMDic[@"localLibVersion"] = HinaDataSDK.sdkInstance.libVersion;
    [self enableRemoteConfig:enableMDic];
}

#pragma mark UI

- (void)showIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.window = [self alertWindow];
        self.window.windowLevel = UIWindowLevelAlert + 1;
        UIViewController *controller = [[HNAlertController alloc] init];
        self.window.rootViewController = controller;
        self.window.hidden = NO;
        self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.indicator.center = CGPointMake(self.window.center.x, self.window.center.y);
        [self.window.rootViewController.view addSubview:self.indicator];
        [self.indicator startAnimating];
    });
}

- (void)hideIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.indicator stopAnimating];
        self.indicator = nil;
        self.window = nil;
    });
}

- (UIWindow *)alertWindow {
#if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= 130000)
    if (@available(iOS 13.0, *)) {
        __block UIWindowScene *scene = nil;
        [[UIApplication sharedApplication].connectedScenes.allObjects enumerateObjectsUsingBlock:^(UIScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIWindowScene class]]) {
                scene = (UIWindowScene *)obj;
                *stop = YES;
            }
        }];
        if (scene) {
            return [[UIWindow alloc] initWithWindowScene:scene];
        }
    }
#endif
    return [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
}


@end
