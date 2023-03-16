//
// HNConfigOptions+AppPush.h
// HinaDataSDK
//
// Created by hina on 2022/9/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNConfigOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNConfigOptions (AppPush)

///开启自动采集通知
@property (nonatomic, assign) BOOL enableTrackPush API_UNAVAILABLE(macos);

@end

NS_ASSUME_NONNULL_END
