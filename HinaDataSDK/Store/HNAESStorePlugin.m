//
// HNAESStorePlugin.m
// HinaDataSDK
//
// Created by hina on 2022/12/1.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNAESStorePlugin.h"
#import "HNAESCrypt.h"
#import "HNFileStorePlugin.h"

static NSString * const kHNAESStorePluginKey = @"StorePlugin.AES";

@interface HNAESStorePlugin ()

@property (nonatomic, strong) NSData *encryptKey;

@property (nonatomic, strong) HNFileStorePlugin *fileStorePlugin;

@property (nonatomic, strong) HNAESCrypt *aesCrypt;

@end

@implementation HNAESStorePlugin

- (instancetype)init {
    self = [super init];
    if (self) {
        _fileStorePlugin = [[HNFileStorePlugin alloc] init];
    }
    return self;
}

#pragma mark - Key

- (NSData *)encryptKey {
    if (!_encryptKey) {
        NSData *data = [self.fileStorePlugin objectForKey:kHNAESStorePluginKey];
        if (data) {
            _encryptKey = [[NSData alloc] initWithBase64EncodedData:data options:0];
        }
    }
    return _encryptKey;
}

- (HNAESCrypt *)aesCrypt {
    if (!_aesCrypt) {
        _aesCrypt = [[HNAESCrypt alloc] initWithKey:self.encryptKey];
    }
    return _aesCrypt;
}

#pragma mark - Base 64

- (NSString *)base64KeyWithString:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:0];
}

#pragma mark - HNStorePlugin

- (nonnull NSString *)type {
    return @"cn.hinadata.AES128.";
}

- (void)upgradeWithOldPlugin:(nonnull id<HNStorePlugin>)oldPlugin {

}

- (nullable id)objectForKey:(nonnull NSString *)key {
    if (!self.encryptKey) {
        return nil;
    }
    NSString *base64Key = [self base64KeyWithString:key];
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:base64Key];
    if (!value) {
        return nil;
    }
    NSData *data = [self.aesCrypt decryptData:[value dataUsingEncoding:NSUTF8StringEncoding]];
    return [NSKeyedUnarchiver unarchiveObjectWithData:data];
}

- (void)setObject:(nullable id)value forKey:(nonnull NSString *)key {
    if (!self.encryptKey) {
        self.encryptKey = self.aesCrypt.key;

        NSData *data = [self.encryptKey base64EncodedDataWithOptions:0];
        [self.fileStorePlugin setObject:data forKey:kHNAESStorePluginKey];
    }
    NSString *base64Key = [self base64KeyWithString:key];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
    NSString *encryptData = [self.aesCrypt encryptData:data];
    [[NSUserDefaults standardUserDefaults] setObject:encryptData forKey:base64Key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeObjectForKey:(nonnull NSString *)key {
    NSString *base64Key = [self base64KeyWithString:key];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:base64Key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
