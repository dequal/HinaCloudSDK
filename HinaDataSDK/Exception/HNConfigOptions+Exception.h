//
// HNConfigOptions+Exception.h
// HinaDataSDK
//
// Created by hina on 2022/9/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNConfigOptions.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNConfigOptions (Exception)

/// 是否自动收集 App Crash 日志，该功能默认是关闭的
@property (nonatomic, assign) BOOL enableTrackAppCrash API_UNAVAILABLE(macos);

@end

NS_ASSUME_NONNULL_END
