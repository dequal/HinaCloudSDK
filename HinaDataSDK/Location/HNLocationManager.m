//
// HNLocationManager.m
// HinaDataSDK
//
// Created by hina on 2022/5/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import <UIKit/UIKit.h>
#import "HNLocationManager.h"
#import "HNConstants+Private.h"
#import "HNLog.h"

static NSString * const kHNEventPresetPropertyLatitude = @"H_latitude";
static NSString * const kHNEventPresetPropertyLongitude = @"H_longitude";
static NSString * const kHNEventPresetPropertyCoordinateSystem = @"H_geo_coordinate_system";
static NSString * const kHNAppleCoordinateSystem = @"WGS84";

@interface HNLocationManager() <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isUpdatingLocation;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

@end

@implementation HNLocationManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNLocationManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNLocationManager alloc] init];
    });
    return manager;
}

- (void)setup {
    if (_locationManager) {
        return;
    }
    //默认设置设置精度为 100 ,也就是 100 米定位一次 ；准确性 kCLLocationAccuracyHundredMeters
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    _locationManager.distanceFilter = 100.0;

    _isUpdatingLocation = NO;

    _coordinate = kCLLocationCoordinate2DInvalid;
    [self setupListeners];
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    _configOptions = configOptions;
    self.enable = configOptions.enableLocation;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - HNLocationManagerProtocol

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    if (enable) {
        [self setup];
        [self startUpdatingLocation];
    } else {
        [self stopUpdatingLocation];
    }
}

- (NSDictionary *)properties {
    if (!CLLocationCoordinate2DIsValid(self.coordinate)) {
        return nil;
    }
    NSInteger latitude = self.coordinate.latitude * pow(10, 6);
    NSInteger longitude = self.coordinate.longitude * pow(10, 6);
    return @{kHNEventPresetPropertyLatitude: @(latitude), kHNEventPresetPropertyLongitude: @(longitude), kHNEventPresetPropertyCoordinateSystem: kHNAppleCoordinateSystem};
}

#pragma mark - Listener

- (void)setupListeners {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

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
    [self stopUpdatingLocation];
}

- (void)remoteConfigManagerModelChanged:(NSNotification *)sender {
    BOOL disableSDK = NO;
    @try {
        disableSDK = [[sender.object valueForKey:@"disableSDK"] boolValue];
    } @catch(NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
    if (disableSDK) {
        [self stopUpdatingLocation];
    } else if (self.enable) {
        [self startUpdatingLocation];
    }
}

#pragma mark - Public

- (void)startUpdatingLocation {
    @try {
        if (self.isUpdatingLocation) {
            return;
        }
        
        // 判断当前设备定位授权的状态
        CLAuthorizationStatus status;
        if (@available(iOS 14.0, *)) {
            status = self.locationManager.authorizationStatus;
        } else {
            status = [CLLocationManager authorizationStatus];
        }
        if ((status == kCLAuthorizationStatusDenied) || (status == kCLAuthorizationStatusRestricted)) {
            HNLogWarn(@"location authorization status is denied or restricted");
            return;
        }

        [self.locationManager requestWhenInUseAuthorization];
        [self.locationManager startUpdatingLocation];
        self.isUpdatingLocation = YES;
    } @catch (NSException *e) {
        HNLogError(@"%@ error: %@", self, e);
    }
}

- (void)stopUpdatingLocation {
    @try {
        if (self.isUpdatingLocation) {
            [self.locationManager stopUpdatingLocation];
            self.isUpdatingLocation = NO;
        }
    }@catch (NSException *e) {
       HNLogError(@"%@ error: %@", self, e);
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations API_AVAILABLE(ios(6.0), macos(10.9)) {
    self.coordinate = locations.lastObject.coordinate;
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    HNLogError(@"enableTrackGPSLocation error：%@", error);
}

@end
