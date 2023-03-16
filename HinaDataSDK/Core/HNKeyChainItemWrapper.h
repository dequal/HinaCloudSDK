//
// HNKeyChainItemWrapper.h
// HinaDataSDK
//
// Created by hina on 2022/3/26.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>

extern  NSString * const kHNService;
extern  NSString * const kHNUdidAccount;

NS_CLASS_AVAILABLE_IOS(8_0)
@interface HNKeyChainItemWrapper : NSObject

+ (NSString *)saUdid;
+ (NSString *)saveUdid:(NSString *)udid;

+ (BOOL)saveOrUpdatePassword:(NSString *)password account:(NSString *)account service:(NSString *)service ;
+ (NSDictionary *)fetchPasswordWithAccount:(NSString *)account service:(NSString *)service ;
+ (BOOL)deletePasswordWithAccount:(NSString *)account service:(NSString *)service ;

+ (BOOL)saveOrUpdatePassword:(NSString *)password account:(NSString *)account service:(NSString *)service accessGroup:(NSString *)accessGroup;
+ (NSDictionary *)fetchPasswordWithAccount:(NSString *)account service:(NSString *)service accessGroup:(NSString *)accessGroup;
+ (BOOL)deletePasswordWithAccount:(NSString *)account service:(NSString *)service accessGroup:(NSString *)accessGroup;

@end
