
#import <Foundation/Foundation.h>
#import "HNConstants.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, HNPropertyPluginPriority) {
    HNPropertyPluginPriorityLow = 250,
    HNPropertyPluginPriorityDefault = 500,
    HNPropertyPluginPriorityHigh = 750,
};

#pragma mark -

@protocol HNPropertyPluginLibFilter <NSObject>

@property (nonatomic, copy, readonly) NSString *lib;
@property (nonatomic, copy, readonly) NSString *method;
@property (nonatomic, copy, readonly) NSString *version;
@property (nonatomic, strong, readonly) id appVersion;

// H_AppClick 和 H_AppViewScreen 全埋点会采集
@property (nonatomic, copy, nullable, readonly) NSString *detail;

@end

@protocol HNPropertyPluginEventFilter <NSObject>

@property (nonatomic, copy, readonly) NSString *event;
@property (nonatomic, assign, readonly) HNEventType type;
@property (nonatomic, assign, readonly) UInt64 time;

@property (nonatomic, strong, readonly) id<HNPropertyPluginLibFilter> lib;

/// 是否为 H5 打通事件
@property (nonatomic, assign, readonly) BOOL hybridH5;

@end

/// 属性插件协议，解决异步插件插件的阻塞问题
@protocol HNPropertyPluginProtocol <NSObject>

@optional

/// 插件注册后会在子线程中调用该方法，用于采集属性。
/// 如果是 UI 操作，请使用 dispatch_async 切换到主线程。
///
/// @Discussion
/// 对于简单的属性插件来说，直接重写 `- properties` 方法返回属性。
///
/// 如果采集的属性需要处理多线程，优先推荐重写 `- prepare` 进行处理。
///
/// 注意：属性采集完成之后，请在最后调用 `- readyWithProperties:`，表示已经完成属性采集。
- (void)prepare;

@end

#pragma mark -

typedef void(^HNPropertyPluginHandler)(NSDictionary<NSString *, id> *properties);

#pragma mark -

/// 属性插件基类
///
/// @Discussion
/// 属性插件需要继承自属性插件基类，通过重写相关方法实现向不同事件中添加属性
///
/// 属性采集有两个方案：
///
/// 方案一：对于简单的属性采集插件来说，直接重写 `- properties` 方法
///
/// 方案二：如插件中需要处理多线程，可以重写 `- prepare` 方法，并在该方法中进行属性采集。
/// 注意：属性采集完成之后，请在最后调用 `- readyWithProperties:`，表示已经完成属性采集。
@interface HNPropertyPlugin : NSObject <HNPropertyPluginProtocol>

/// 属性优先级
///
/// 默认为： HNPropertyPluginPriorityDefault
- (HNPropertyPluginPriority)priority;

/// 通过事件筛选器来判断是否匹配当前插件
///
/// 属性插件可以通过重写该方法，来决定是否在事件 filter 中加入属性
///
/// @param filter 事件相关信息的筛选器，包含事件相关信息
/// @return 是否匹配
- (BOOL)isMatchedWithFilter:(id<HNPropertyPluginEventFilter>)filter;

/// 属性插件采集的属性
///
/// 对于简单的属性插件，只需重写这个方法返回属性即可，基类默认实现并返回 nil
///
/// @return 属性
- (NSDictionary<NSString *, id> *)properties;

@end

#pragma mark -

@interface HNPropertyPlugin (HNPublic)

@property (nonatomic, strong, readonly, nullable) id<HNPropertyPluginEventFilter> filter;

/// 请在 `- prepare` 方法执行完成后调用这个方法
/// @param properties 采集到的属性
- (void)readyWithProperties:(NSDictionary<NSString *, id> *)properties;

@end

NS_ASSUME_NONNULL_END
