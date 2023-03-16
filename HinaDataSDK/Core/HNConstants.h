//
// HNConstants.h
// HinaDataSDK
//
// Created by hina on 2022/8/9.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>


#pragma mark - typedef
/**
 * @abstract
 * Debug 模式，用于检验数据导入是否正确。该模式下，事件会逐条实时发送到 HinaData，并根据返回值检查
 * 数据导入是否正确。
 *
 * @discussion
 * Debug 模式的具体使用方式，请参考:
 *  http://www.hinadata.cn/manual/debug_mode.html
 *
 * Debug模式有三种选项:
 *   HinaDataDebugOff - 关闭 DEBUG 模式
 *   HinaDataDebugOnly - 打开 DEBUG 模式，但该模式下发送的数据仅用于调试，不进行数据导入
 *   HinaDataDebugAndTrack - 打开 DEBUG 模式，并将数据导入到 HinaData 中
 */
typedef NS_ENUM(NSInteger, HinaDataDebugMode) {
    HinaDataDebugOff,
    HinaDataDebugOnly,
    HinaDataDebugAndTrack,
};

/**
 * @abstract
 * TrackTimer 接口的时间单位。调用该接口时，传入时间单位，可以设置 event_duration 属性的时间单位。
 *
 * @discuss
 * 时间单位有以下选项：
 *   HinaDataTimeUnitMilliseconds - 毫秒
 *   HinaDataTimeUnitSeconds - 秒
 *   HinaDataTimeUnitMinutes - 分钟
 *   HinaDataTimeUnitHours - 小时
 */
typedef NS_ENUM(NSInteger, HinaDataTimeUnit) {
    HinaDataTimeUnitMilliseconds,
    HinaDataTimeUnitSeconds,
    HinaDataTimeUnitMinutes,
    HinaDataTimeUnitHours
};


/**
 * @abstract
 * AutoTrack 中的事件类型
 *
 * @discussion
 *   HinaDataEventTypeAppStart - H_AppStart
 *   HinaDataEventTypeAppEnd - H_AppEnd
 *   HinaDataEventTypeAppClick - H_AppClick
 *   HinaDataEventTypeAppViewScreen - H_AppViewScreen
 */
typedef NS_OPTIONS(NSInteger, HinaDataAutoTrackEventType) {
    HinaDataEventTypeNone      = 0,
    HinaDataEventTypeAppStart      = 1 << 0,
    HinaDataEventTypeAppEnd        = 1 << 1,
    HinaDataEventTypeAppClick      = 1 << 2,
    HinaDataEventTypeAppViewScreen = 1 << 3,
};

/**
 * @abstract
 * 网络类型
 *
 * @discussion
 *   HinaDataNetworkTypeNONE - NULL
 *   HinaDataNetworkType2G - 2G
 *   HinaDataNetworkType3G - 3G
 *   HinaDataNetworkType4G - 4G
 *   HinaDataNetworkTypeWIFI - WIFI
 *   HinaDataNetworkTypeALL - ALL
 *   HinaDataNetworkType5G - 5G   
 */
typedef NS_OPTIONS(NSInteger, HinaDataNetworkType) {
    HinaDataNetworkTypeNONE         = 0,
    HinaDataNetworkType2G API_UNAVAILABLE(macos)    = 1 << 0,
    HinaDataNetworkType3G API_UNAVAILABLE(macos)    = 1 << 1,
    HinaDataNetworkType4G API_UNAVAILABLE(macos)    = 1 << 2,
    HinaDataNetworkTypeWIFI     = 1 << 3,
    HinaDataNetworkTypeALL      = 0xFF,
#ifdef __IPHONE_14_1
    HinaDataNetworkType5G API_UNAVAILABLE(macos)   = 1 << 4
#endif
};

/// 事件类型
typedef NS_OPTIONS(NSUInteger, HNEventType) {
    HNEventTypeTrack = 1 << 0,
    HNEventTypeSignup = 1 << 1,
    HNEventTypeBind = 1 << 2,
    HNEventTypeUnbind = 1 << 3,

    HNEventTypeProfileSet = 1 << 4,
    HNEventTypeProfileSetOnce = 1 << 5,
    HNEventTypeProfileUnset = 1 << 6,
    HNEventTypeProfileDelete = 1 << 7,
    HNEventTypeProfileAppend = 1 << 8,
    HNEventTypeIncrement = 1 << 9,

    HNEventTypeItemSet = 1 << 10,
    HNEventTypeItemDelete = 1 << 11,

    HNEventTypeDefault = 0xF,
    HNEventTypeAll = 0xFFFFFFFF,
};

typedef NSString *HNLimitKey NS_TYPED_EXTENSIBLE_ENUM;
FOUNDATION_EXTERN HNLimitKey const HNLimitKeyIDFA;
FOUNDATION_EXTERN HNLimitKey const HNLimitKeyIDFV;
FOUNDATION_EXTERN HNLimitKey const HNLimitKeyCarrier;
