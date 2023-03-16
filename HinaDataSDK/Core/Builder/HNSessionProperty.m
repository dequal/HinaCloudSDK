//
// HNSessionProperty.m
// HinaDataSDK
//
// Created by hina on 2022/12/23.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNSessionProperty.h"
#import "HNStoreManager.h"

/// session 标记
static NSString * const kHNEventPropertySessionID = @"H_event_session_id";
/// session 数据模型
static NSString * const kHNSessionModelKey = @"HNSessionModel";
/// session 最大时长是 12 小时（单位为毫秒）
static const NSUInteger kHNSessionMaxDuration = 12 * 60 * 60 * 1000;

#pragma mark - HNSessionModel

@interface HNSessionModel : NSObject <NSCoding>

/// session 标识
@property (nonatomic, copy) NSString *sessionID;
/// 首个事件的触发时间
@property (nonatomic, strong) NSNumber *firstEventTime;
/// 最后一个事件的触发时间
@property (nonatomic, strong) NSNumber *lastEventTime;

@end

@implementation HNSessionModel

- (instancetype)init {
    self = [super init];
    if (self) {
        _sessionID = [NSUUID UUID].UUIDString;
        _firstEventTime = @(0);
        _lastEventTime = @(0);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.sessionID forKey:@"sessionID"];
    [coder encodeObject:self.firstEventTime forKey:@"firstEventTime"];
    [coder encodeObject:self.lastEventTime forKey:@"lastEventTime"];
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    if (self) {
        self.sessionID = [coder decodeObjectForKey:@"sessionID"];
        self.firstEventTime = [coder decodeObjectForKey:@"firstEventTime"];
        self.lastEventTime = [coder decodeObjectForKey:@"lastEventTime"];
    }
    return self;
}

- (NSString *)description {
    return [[NSString alloc] initWithFormat:@"<%@:%p>, \n sessionID = %@, \n firstEventTime = %@, \n lastEventTime = %@", self.class, self, self.sessionID, self.firstEventTime, self.lastEventTime];
}

@end

#pragma mark - HNSessionProperty

@interface HNSessionProperty ()

@property (nonatomic, strong) HNSessionModel *sessionModel;
@property (nonatomic, assign) NSInteger sessionMaxInterval;

@end

@implementation HNSessionProperty

#pragma mark - Public

+ (void)removeSessionModel {
    [[HNStoreManager sharedInstance] removeObjectForKey:kHNSessionModelKey];
}

- (instancetype)initWithMaxInterval:(NSInteger)maxInterval {
    self = [super init];
    if (self) {
        _sessionMaxInterval = maxInterval;
    }
    return self;
}

- (NSDictionary *)sessionPropertiesWithEventTime:(NSNumber *)eventTime {
    NSNumber *maxIntervalEventTime = @(self.sessionModel.lastEventTime.unsignedLongLongValue + self.sessionMaxInterval);
    NSNumber *maxDurationEventTime = @(self.sessionModel.firstEventTime.unsignedLongLongValue + kHNSessionMaxDuration);
    
    // 重新生成 session
    if (([eventTime compare:maxIntervalEventTime] == NSOrderedDescending) ||
        ([eventTime compare:maxDurationEventTime] == NSOrderedDescending)) {
        self.sessionModel.sessionID = [NSUUID UUID].UUIDString;
        self.sessionModel.firstEventTime = eventTime;
    }
    
    // 更新最近一次事件的触发时间
    self.sessionModel.lastEventTime = eventTime;
    
    // session 保存本地
    [[HNStoreManager sharedInstance] setObject:self.sessionModel forKey:kHNSessionModelKey];
    
    return @{kHNEventPropertySessionID : self.sessionModel.sessionID};
}

#pragma mark - Getters and Setters

/// 懒加载是为了防止在初始化的时候同步读取文件
- (HNSessionModel *)sessionModel {
    if (!_sessionModel) {
        _sessionModel = [[HNStoreManager sharedInstance] objectForKey:kHNSessionModelKey] ?: [[HNSessionModel alloc] init];
    }
    return _sessionModel;
}

@end
