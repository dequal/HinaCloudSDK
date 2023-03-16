//
// HNRemoteConfigModel.m
// HinaDataSDK
//
// Created by hina on 2022/7/20.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNRemoteConfigModel.h"
#import "HNValidator.h"

static id dictionaryValueForKey(NSDictionary *dic, NSString *key) {
    if (![HNValidator isValidDictionary:dic]) {
        return nil;
    }
    
    id value = dic[key];
    return (value && ![value isKindOfClass:NSNull.class]) ? value : nil;
}

@implementation HNRemoteConfigModel

#pragma mark - Life Cycle

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
        _originalVersion = dictionaryValueForKey(dictionary, @"v");
        _localLibVersion = dictionaryValueForKey(dictionary, @"localLibVersion");
        
        NSDictionary *configs = dictionaryValueForKey(dictionary, @"configs");
        _latestVersion = dictionaryValueForKey(configs, @"nv");
        _disableSDK = [dictionaryValueForKey(configs, @"disableSDK") boolValue];
        _disableDebugMode = [dictionaryValueForKey(configs, @"disableDebugMode") boolValue];
        _eventBlackList = dictionaryValueForKey(configs, @"event_blacklist");
        
        [self setupAutoTrackMode:configs];
        [self setupEffectMode:configs];
    }
    return self;
}

- (void)setupAutoTrackMode:(NSDictionary *)dictionary {
    _autoTrackMode = kHNAutoTrackModeDefault;
    
    NSNumber *autoTrackMode = dictionaryValueForKey(dictionary, @"autoTrackMode");
    if (autoTrackMode) {
        NSInteger remoteAutoTrackMode = autoTrackMode.integerValue;
        if (remoteAutoTrackMode >= kHNAutoTrackModeDefault && remoteAutoTrackMode <= kHNAutoTrackModeEnabledAll) {
            _autoTrackMode = remoteAutoTrackMode;
        }
    }
}

- (void)setupEffectMode:(NSDictionary *)dictionary {
    _effectMode = HNRemoteConfigEffectModeNext;
    
    NSNumber *effectMode = dictionaryValueForKey(dictionary, @"effect_mode");
    if (effectMode && (effectMode.integerValue == 1)) {
        _effectMode = HNRemoteConfigEffectModeNow;
    }
}

#pragma mark - Public Methods

- (NSDictionary *)toDictionary {
    NSMutableDictionary *mDic = [NSMutableDictionary dictionaryWithCapacity:3];
    mDic[@"v"] = self.originalVersion;
    mDic[@"localLibVersion"] = self.localLibVersion;
    mDic[@"configs"] = [self configsDictionary];
    return mDic;
}

#pragma mark – Private Methods

- (NSDictionary *)configsDictionary {
    NSMutableDictionary *configs = [NSMutableDictionary dictionaryWithCapacity:6];
    configs[@"nv"] = self.latestVersion;
    configs[@"disableSDK"] = [NSNumber numberWithBool:self.disableSDK];
    configs[@"disableDebugMode"] = [NSNumber numberWithBool:self.disableDebugMode];
    configs[@"event_blacklist"] = self.eventBlackList;
    configs[@"autoTrackMode"] = [NSNumber numberWithInteger:self.autoTrackMode];
    configs[@"effect_mode"] = [NSNumber numberWithInteger:self.effectMode];
    return configs;
}

- (NSString *)description {
    return [[NSString alloc] initWithFormat:@"<%@:%p>, \n v=%@, \n configs=%@, \n localLibVersion=%@", self.class, self, self.originalVersion, [self configsDictionary], self.localLibVersion];
}

@end
