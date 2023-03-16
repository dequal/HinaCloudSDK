//
// HNTrackEventObject.h
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNBaseEventObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNTrackEventObject : HNBaseEventObject

- (instancetype)initWithEventId:(NSString *)eventId NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@end

@interface HNSignUpEventObject : HNTrackEventObject

@end

@interface HNCustomEventObject : HNTrackEventObject

@end

/// 自动采集全埋点事件：
/// H_AppStart、H_AppEnd、H_AppViewScreen、H_AppClick
@interface HNAutoTrackEventObject : HNTrackEventObject

@end

/// 采集预置事件
/// H_AppStart、H_AppEnd、H_AppViewScreen、H_AppClick 全埋点事件
/// AppCrashed、H_AppRemoteConfigChanged 等预置事件
@interface HNPresetEventObject : HNTrackEventObject

@end

/// 绑定 ID 事件
@interface HNBindEventObject : HNTrackEventObject

@end

/// 解绑 ID 事件
@interface HNUnbindEventObject : HNTrackEventObject

@end

NS_ASSUME_NONNULL_END
