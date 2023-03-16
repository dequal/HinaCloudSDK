//
// HNAlertController.m
// HinaDataSDK
//
// Created by hina on 2022/3/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAlertController.h"

#pragma mark - HNAlertAction
@interface HNAlertAction ()
@property (nonatomic) NSInteger tag;
@end
@implementation HNAlertAction

+ (instancetype)actionWithTitle:(nullable NSString *)title style:(HNAlertActionStyle)style handler:(void (^ __nullable)(HNAlertAction *))handler {
    HNAlertAction *action = [[HNAlertAction alloc] init];
    action.title = title;
    action.style = style;
    action.handler = handler;
    return action;
}

@end

#if TARGET_OS_IOS

#pragma mark - HNAlertController
@interface HNAlertController () <UIAlertViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UIWindow *alertWindow;

@property (nonatomic, copy) NSString *alertTitle;
@property (nonatomic, copy) NSString *alertMessage;
@property (nonatomic) HNAlertControllerStyle preferredStyle;

@property (nonatomic, strong) NSMutableArray<HNAlertAction *> *actions;

@end

@implementation HNAlertController

- (instancetype)initWithTitle:(nullable NSString *)title message:(nullable NSString *)message preferredStyle:(HNAlertControllerStyle)preferredStyle {
    self = [super init];
    if (self) {
        _alertTitle = title;
        _alertMessage = message;
        _preferredStyle = preferredStyle;
        _actions = [NSMutableArray arrayWithCapacity:4];

        UIWindow *alertWindow = [self currentAlertWindow];
        alertWindow.windowLevel = UIWindowLevelAlert + 1;
        alertWindow.rootViewController = self;
        alertWindow.hidden = NO;
        _alertWindow = alertWindow;
    }
    return self;
}

- (void)addActionWithTitle:(NSString *)title style:(HNAlertActionStyle)style handler:(void (^ __nullable)(HNAlertAction *))handler {
    HNAlertAction *action = [HNAlertAction actionWithTitle:title style:style handler:handler];
    [self.actions addObject:action];
}

- (void)show {
    [self showAlertController];
}

- (void)showAlertController {
    UIAlertControllerStyle style = self.preferredStyle == HNAlertControllerStyleAlert ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:self.alertTitle message:self.alertMessage preferredStyle:style];

    for (HNAlertAction *action in self.actions) {
        UIAlertActionStyle style = UIAlertActionStyleDefault;
        switch (action.style) {
            case HNAlertActionStyleCancel:
                style = UIAlertActionStyleCancel;
                break;
            case HNAlertActionStyleDestructive:
                style = UIAlertActionStyleDestructive;
                break;
            default:
                style = UIAlertActionStyleDefault;
                break;
        }
        UIAlertAction *alertAction = [UIAlertAction actionWithTitle:action.title style:style handler:^(UIAlertAction *alertAction) {
            if (action.handler) {
                action.handler(action);
            }
            self.alertWindow.hidden = YES;
            self.alertWindow = nil;
        }];
        [alertController addAction:alertAction];
    }
    [self.actions removeAllObjects];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (UIWindow *)currentAlertWindow {
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

#endif
