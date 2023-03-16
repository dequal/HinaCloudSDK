//
// HinaDataSDK+Location.h
// HinaDataSDK
//
// Created by hina on 2022/9/11.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HinaDataSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface HinaDataSDK (Location)

/**
 * @abstract
 * 位置信息采集功能开关
 *
 * @discussion
 * 根据需要决定是否开启位置采集
 * 默认关闭
 *
 * @param enable YES/NO
 */
- (void)enableTrackGPSLocation:(BOOL)enable API_UNAVAILABLE(macos);

@end

NS_ASSUME_NONNULL_END
