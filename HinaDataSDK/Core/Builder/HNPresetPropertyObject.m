//
// HNPresetPropertyObject.m
// HinaDataSDK
//
// Created by hina on 2022/1/7.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNPresetPropertyObject.h"
#include <sys/sysctl.h>
#import "HNLog.h"
#import "HNJSONUtil.h"
#import "HNConstants+Private.h"

#if TARGET_OS_IOS
#import <UIKit/UIKit.h>
#elif TARGET_OS_OSX
#import <AppKit/AppKit.h>
#endif

@implementation HNPresetPropertyObject

#pragma mark - device
/// 型号
static NSString * const kHNEventPresetPropertyPluginModel = @"H_model";
/// 生产商
static NSString * const kHNEventPresetPropertyPluginManufacturer = @"H_manufacturer";
/// 屏幕高
static NSString * const kHNEventPresetPropertyPluginScreenHeight = @"H_screen_height";
/// 屏幕宽
static NSString * const kHNEventPresetPropertyPluginScreenWidth = @"H_screen_width";

#pragma mark - os
/// 系统
static NSString * const kHNEventPresetPropertyPluginOS = @"H_os";
/// 系统版本
static NSString * const kHNEventPresetPropertyPluginOSVersion = @"H_os_version";

#pragma mark - app
/// 应用 ID
static NSString * const HNEventPresetPropertyPluginAppID = @"H_app_id";
/// 应用名称
static NSString * const kHNEventPresetPropertyPluginAppName = @"H_app_name";
/// 时区偏移量
static NSString * const kHNEventPresetPropertyPluginTimezoneOffset = @"H_timezone_offset";

#pragma mark - lib
/// SDK 类型
NSString * const kHNEventPresetPropertyPluginLib = @"H_lib";

#pragma mark - preset property
- (NSString *)manufacturer {
    return @"Apple";
}

- (NSString *)os {
    return nil;
}

- (NSString *)osVersion {
    return nil;
}

- (NSString *)deviceModel {
    return nil;
}

- (NSString *)lib {
    return nil;
}

- (NSInteger)screenHeight {
    return 0;
}

- (NSInteger)screenWidth {
    return 0;
}

- (NSString *)carrier {
    return nil;
}

- (NSString *)appID {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

- (NSString *)appName {
    NSString *displayName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (displayName.length > 0) {
        return displayName;
    }

    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    if (bundleName.length > 0) {
        return bundleName;
    }

    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];
}

- (NSInteger)timezoneOffset {
    // 计算时区偏移（保持和 JS 获取时区偏移的计算结果一致，这里首先获取分钟数，然后取反）
    NSInteger minutesOffsetGMT = - ([[NSTimeZone defaultTimeZone] secondsFromGMT] / 60);
    return minutesOffsetGMT;
}

- (NSMutableDictionary<NSString *, id> *)properties {
    NSMutableDictionary<NSString *, id> *properties = [NSMutableDictionary dictionary];
    properties[kHNEventPresetPropertyPluginModel] = self.deviceModel;
    properties[kHNEventPresetPropertyPluginManufacturer] = self.manufacturer;
    properties[kHNEventPresetPropertyPluginOS] = self.os;
    properties[kHNEventPresetPropertyPluginOSVersion] = self.osVersion;
    properties[kHNEventPresetPropertyPluginLib] = self.lib;
    properties[HNEventPresetPropertyPluginAppID] = self.appID;
    properties[kHNEventPresetPropertyPluginAppName] = self.appName;
    properties[kHNEventPresetPropertyPluginScreenHeight] = @(self.screenHeight);
    properties[kHNEventPresetPropertyPluginScreenWidth] = @(self.screenWidth);
    properties[kHNEventPresetPropertyPluginTimezoneOffset] = @(self.timezoneOffset);
    return properties;
}

#pragma mark - util
- (NSString *)sysctlByName:(NSString *)name {
    NSString *result = nil;
    @try {
        size_t size;
        sysctlbyname([name UTF8String], NULL, &size, NULL, 0);
        char answer[size];
        sysctlbyname([name UTF8String], answer, &size, NULL, 0);
        if (size) {
            result = @(answer);
        } else {
            HNLogError(@"Failed fetch %@ from sysctl.", name);
        }
    } @catch (NSException *exception) {
        HNLogError(@"%@: %@", self, exception);
    }
    return result;
}

@end

#if TARGET_OS_IOS
@implementation HNPhonePresetProperty

- (NSString *)deviceModel {
    return [self sysctlByName:@"hw.machine"];
}

- (NSString *)lib {
    return @"iOS";
}

- (NSString *)os {
    return @"iOS";
}

- (NSString *)osVersion {
    return [[UIDevice currentDevice] systemVersion];
}

- (NSInteger)screenHeight {
    return (NSInteger)UIScreen.mainScreen.bounds.size.height;
}

- (NSInteger)screenWidth {
    return (NSInteger)UIScreen.mainScreen.bounds.size.width;
}

@end

@implementation HNCatalystPresetProperty

- (NSString *)deviceModel {
    return [self sysctlByName:@"hw.model"];
}

- (NSString *)lib {
    return @"iOS";
}

- (NSString *)os {
    return @"macOS";
}

- (NSString *)osVersion {
    return [self sysctlByName:@"kern.osproductversion"];
}

- (NSInteger)screenHeight {
    return (NSInteger)UIScreen.mainScreen.bounds.size.height;
}

- (NSInteger)screenWidth {
    return (NSInteger)UIScreen.mainScreen.bounds.size.width;
}

@end
#endif

#if TARGET_OS_OSX
@implementation HNMacPresetProperty

- (NSString *)deviceModel {
    return [self sysctlByName:@"hw.model"];
}

- (NSString *)lib {
    return @"macOS";
}

- (NSString *)os {
    return @"macOS";
}

- (NSString *)osVersion {
    NSDictionary *systemVersion = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    return systemVersion[@"ProductVersion"];
}

- (NSInteger)screenHeight {
    return (NSInteger)NSScreen.mainScreen.frame.size.height;
}

- (NSInteger)screenWidth {
    return (NSInteger)NSScreen.mainScreen.frame.size.width;
}

@end
#endif
