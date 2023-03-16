//
// HNFileStorePlugin.m
// HinaDataSDK
//
// Created by hina on 2022/12/1.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNFileStorePlugin.h"

static NSString * const kHNFileStorePluginType = @"cn.hinadata.File.";

@implementation HNFileStorePlugin

+ (NSString *)filePath:(NSString *)key {
    NSString *name = [key stringByReplacingOccurrencesOfString:kHNFileStorePluginType withString:@""];
#if TARGET_OS_OSX
    // 兼容老版 mac SDK 的本地数据
    NSString *filename = [NSString stringWithFormat:@"com.hinadata.analytics.mini.HinaDataSDK.%@.plist", name];
#else
    NSString *filename = [NSString stringWithFormat:@"hinadata-%@.plist", name];
#endif

    NSString *filepath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
                          stringByAppendingPathComponent:filename];
    return filepath;
}

#pragma mark - HNStorePlugin

- (NSArray<NSString *> *)storeKeys {
    return @[@"H_channel_device_info", @"login_id", @"account_id", @"com.hinadata.loginidkey", @"com.hinadata.identities", @"first_day", @"super_properties", @"latest_utms", @"HNEncryptSecretKey", @"HNVisualPropertiesConfig", @"HNSessionModel"];
}

- (NSString *)type {
    return kHNFileStorePluginType;
}

- (void)upgradeWithOldPlugin:(nonnull id<HNStorePlugin>)oldPlugin {

}

- (nullable id)objectForKey:(nonnull NSString *)key {
    if (!key) {
        return nil;
    }
    NSString *filePath = [HNFileStorePlugin filePath:key];
    @try {
        return [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
    } @catch (NSException *exception) {
        return nil;
    }
}

- (void)setObject:(nullable id)value forKey:(nonnull NSString *)key {
    if (!key) {
        return;
    }
    NSString *filePath = [HNFileStorePlugin filePath:key];
#if TARGET_OS_IOS
    /* 为filePath文件设置保护等级 */
    NSDictionary *protection = [NSDictionary dictionaryWithObject:NSFileProtectionComplete
                                                           forKey:NSFileProtectionKey];
#elif TARGET_OS_OSX
    // macOS10.13 不包含 NSFileProtectionComplete
    NSDictionary *protection = [NSDictionary dictionary];
#endif

    [[NSFileManager defaultManager] setAttributes:protection
                                     ofItemAtPath:filePath
                                            error:nil];
    [NSKeyedArchiver archiveRootObject:value toFile:filePath];
}

- (void)removeObjectForKey:(nonnull NSString *)key {
    NSString *filePath = [HNFileStorePlugin filePath:key];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
}

@end
