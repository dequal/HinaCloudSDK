//
// HinaDataSDK+DebugMode.h
// HinaDataSDK
//
// Created by hina on 2022/9/11.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HinaDataSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface HinaDataSDK (DebugMode)

/**
 * @abstract
 * 设置是否显示 debugInfoView，对于 iOS，是 UIAlertView／UIAlertController
 *
 * @discussion
 * 设置是否显示 debugInfoView，默认显示
 *
 * @param show             是否显示
 */
- (void)showDebugInfoView:(BOOL)show API_UNAVAILABLE(macos);

- (HinaDataDebugMode)debugMode;

@end

NS_ASSUME_NONNULL_END
