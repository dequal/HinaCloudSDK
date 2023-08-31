
#import <Foundation/Foundation.h>


/// 位运算:
/// 位左移（<<）运算
/// a << b就表示把a转为二进制后左移b位（在后面添b个0; a << b的值实际上就是a乘以2的b次方
/// a >> b表示二进制右移b位（去掉末b位）;  相当于a除以2的b次方




#pragma mark - typedef
/**
 * @abstract
 * Debug 模式，用于检验数据导入是否正确。该模式下，事件会逐条实时发送并根据返回值检查
 * 数据导入是否正确。
 *
 * @discussion
 *
 * Debug模式有三种选项:
 *   HinaCloudDebugOff - 关闭 DEBUG 模式
 *   HinaCloudDebugOnly - 打开 DEBUG 模式，但该模式下发送的数据仅用于调试，不进行数据导入
 *   HinaCloudDebugAndTrack - 打开 DEBUG 模式，并将数据导入
 */
typedef NS_ENUM(NSInteger, HinaCloudDebugMode) {
    HinaCloudDebugOff,
    HinaCloudDebugOnly,
    HinaCloudDebugAndTrack,
};

/**
 * @abstract
 * TrackTimer 接口的时间单位。调用该接口时，传入时间单位，可以设置 event_duration 属性的时间单位。
 *
 * @discuss
 * 时间单位有以下选项：
 *   HinaCloudTimeUnitMilliseconds - 毫秒
 *   HinaCloudTimeUnitSeconds - 秒
 *   HinaCloudTimeUnitMinutes - 分钟
 *   HinaCloudTimeUnitHours - 小时
 */
typedef NS_ENUM(NSInteger, HinaCloudTimeUnit) {
    HinaCloudTimeUnitMilliseconds,
    HinaCloudTimeUnitSeconds,
    HinaCloudTimeUnitMinutes,
    HinaCloudTimeUnitHours
};


/**
 * @abstract
 * AutoTrack 中的事件类型
 *
 * @discussion
 *   HNAutoTrackAppStart - H_AppStart
 *   HNAutoTrackAppEnd - H_AppEnd
 *   HNAutoTrackAppClick - H_AppClick
 *   HNAutoTrackAppScreen - H_AppViewScreen
 */
typedef NS_OPTIONS(NSInteger, HinaCloudAutoTrackEventType) {
    HNAutoTrackNone      = 0,
    HNAutoTrackAppStart      = 1 << 0,
    HNAutoTrackAppEnd        = 1 << 1,
    HNAutoTrackAppClick      = 1 << 2,
    HNAutoTrackAppScreen = 1 << 3,
};

/**
 * @abstract
 * 网络类型
 *
 * @discussion
 *   HNNetworkTypeNONE - NULL
 *   HNNetworkType2G - 2G
 *   HNNetworkType3G - 3G
 *   HNNetworkType4G - 4G
 *   HNNetworkTypeWIFI - WIFI
 *   HNNetworkTypeALL - ALL
 *   HNNetworkType5G - 5G   
 */
typedef NS_OPTIONS(NSInteger, HNNetworkType) {
    HNNetworkTypeNONE         = 0,
    HNNetworkType2G API_UNAVAILABLE(macos)    = 1 << 0,
    HNNetworkType3G API_UNAVAILABLE(macos)    = 1 << 1,
    HNNetworkType4G API_UNAVAILABLE(macos)    = 1 << 2,
    HNNetworkTypeWIFI     = 1 << 3,
    HNNetworkTypeALL      = 0xFF,
#ifdef __IPHONE_14_1
    HNNetworkType5G API_UNAVAILABLE(macos)   = 1 << 4
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
