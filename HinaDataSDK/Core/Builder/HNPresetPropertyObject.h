//
// HNPresetPropertyObject.h
// HinaDataSDK
//
// Created by hina on 2022/1/7.
// Copyright © 2022 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface HNPresetPropertyObject : NSObject

- (NSString *)manufacturer;
- (NSString *)os;
- (NSString *)osVersion;
- (NSString *)deviceModel;
- (NSString *)lib;
- (NSInteger)screenHeight;
- (NSInteger)screenWidth;
- (NSString *)carrier;
- (NSString *)appID;
- (NSString *)appName;
- (NSInteger)timezoneOffset;

- (NSMutableDictionary<NSString *, id> *)properties;

@end

#if TARGET_OS_IOS
@interface HNPhonePresetProperty : HNPresetPropertyObject

@end

@interface HNCatalystPresetProperty : HNPresetPropertyObject

@end
#endif

#if TARGET_OS_OSX
@interface HNMacPresetProperty : HNPresetPropertyObject

@end
#endif

NS_ASSUME_NONNULL_END
