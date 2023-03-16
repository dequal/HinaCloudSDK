//
// HNDeviceOrientationManager.m
// HinaDataSDK
//
// Created by hina on 2022/5/21.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <UIKit/UIKit.h>
#import "HNDeviceOrientationManager.h"
#import "HNConstants+Private.h"
#import "HNLog.h"

static NSTimeInterval const kHNDefaultDeviceMotionUpdateInterval = 0.5;
static NSString * const kHNEventPresetPropertyScreenOrientation = @"H_screen_orientation";

@interface HNDeviceOrientationManager()

@property (nonatomic, strong) CMMotionManager *cmmotionManager;
@property (nonatomic, strong) NSOperationQueue *updateQueue;
@property (nonatomic, strong) NSString *deviceOrientation;

@end

@implementation HNDeviceOrientationManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNDeviceOrientationManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNDeviceOrientationManager alloc] init];
    });
    return manager;
}

- (void)setup {
    if (_cmmotionManager) {
        return;
    }
    _cmmotionManager = [[CMMotionManager alloc] init];
    _cmmotionManager.deviceMotionUpdateInterval = kHNDefaultDeviceMotionUpdateInterval;
    _updateQueue = [[NSOperationQueue alloc] init];
    _updateQueue.name = @"com.hinadata.analytics.deviceMotionUpdatesQueue";

    [self setupListeners];
}

#pragma mark - HNModuleProtocol

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        [self setup];
        [self startDeviceMotionUpdates];
    } else {
        self.deviceOrientation = nil;
        [self stopDeviceMotionUpdates];
    }
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    _configOptions = configOptions;
    self.enable = configOptions.enableDeviceOrientation;
}

- (NSDictionary *)properties {
    return self.deviceOrientation ? @{kHNEventPresetPropertyScreenOrientation: self.deviceOrientation} : nil;
}

#pragma mark - Listener

- (void)setupListeners {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    // 这里只需要监听 App 进入后台的原因是在应用启动的时候，远程配置都会去主动开启设备方向监听
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(remoteConfigManagerModelChanged:)
                               name:HN_REMOTE_CONFIG_MODEL_CHANGED_NOTIFICATION
                             object:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self stopDeviceMotionUpdates];
}

- (void)remoteConfigManagerModelChanged:(NSNotification *)sender {
    BOOL disableSDK = NO;
    @try {
        disableSDK = [[sender.object valueForKey:@"disableSDK"] boolValue];
    } @catch(NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
    if (disableSDK) {
        [self stopDeviceMotionUpdates];
    } else if (self.enable) {
        [self startDeviceMotionUpdates];
    }
}

#pragma mark - Public

- (void)startDeviceMotionUpdates {
    if (self.cmmotionManager.isDeviceMotionAvailable && !self.cmmotionManager.isDeviceMotionActive) {
        __weak HNDeviceOrientationManager *weakSelf = self;
        [self.cmmotionManager startDeviceMotionUpdatesToQueue:self.updateQueue withHandler:^(CMDeviceMotion * _Nullable motion, NSError * _Nullable error) {
            [weakSelf handleDeviceMotion:motion];
        }];
    }
}

- (void)stopDeviceMotionUpdates {
    if (self.cmmotionManager.isDeviceMotionActive) {
        [self.cmmotionManager stopDeviceMotionUpdates];
    }
}

- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion {
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    if (fabs(y)  >= fabs(x)) {
        //y>0  UIDeviceOrientationPortraitUpsideDown;
        //y<0  UIDeviceOrientationPortrait;
        self.deviceOrientation = @"portrait";
    } else if (fabs(x) >= fabs(y)) {
        //x>0  UIDeviceOrientationLandscapeRight;
        //x<0  UIDeviceOrientationLandscapeLeft;
        self.deviceOrientation = @"landscape";
    }
}

- (void)dealloc {
    [self stopDeviceMotionUpdates];
    [self.updateQueue cancelAllOperations];
    [self.updateQueue waitUntilAllOperationsAreFinished];
    self.updateQueue = nil;
    self.cmmotionManager = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
