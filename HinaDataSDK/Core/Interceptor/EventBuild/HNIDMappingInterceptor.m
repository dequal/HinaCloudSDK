//
// HNIDMappingInterceptor.m
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNIDMappingInterceptor.h"
#import "HNIdentifier.h"


#pragma mark -

@interface HNIDMappingInterceptor()

@property (nonatomic, weak) HNIdentifier *identifier;

@end

@implementation HNIDMappingInterceptor

- (void)processWithInput:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(input.eventObject);

    HNBaseEventObject *object = input.eventObject;
    // item 操作，不采集用户 Id 信息
    if (object.type == HNEventTypeItemSet || object.type == HNEventTypeItemDelete) {
        return completion(input);
    }

    NSParameterAssert(input.identifier);
    self.identifier = input.identifier;

    // 设置用户关联信息
    if (object.hybridH5 && object.type & HNEventTypeSignup) {
        [self identifyTrackFromH5WithEventObject:object];
    } else {
        [self identifyTrackWithEventObject:object];
    }
    
    completion(input);
}

// 普通 track 事件用户关联
- (void)identifyTrackWithEventObject:(HNBaseEventObject *)object {
    NSDictionary *identities = object.identities;

    // 设置用户关联信息
    NSString *anonymousId = self.identifier.anonymousId;
    object.distinctId = self.identifier.distinctId;
    object.anonymousId = anonymousId;
    object.originalId = anonymousId;

    if (object.hybridH5) {
        // 只有当本地 loginId 不为空时才覆盖 H5 数据
        if (self.identifier.loginId) {
            object.loginId = self.identifier.loginId;
        }
        // 先设置 loginId 后再设置 identities。identities 对 loginId 有依赖
        object.identities = [self.identifier mergeH5Identities:identities eventType:object.type];
    } else {
        object.loginId = self.identifier.loginId;
        object.identities = [self.identifier identitiesWithEventType:object.type];
    }
}

// H5 打通事件，用户关联
- (void)identifyTrackFromH5WithEventObject:(HNBaseEventObject *)object {

    NSDictionary *identities = object.identities;
    void(^loginBlock)(NSString *, NSString *)  = ^(NSString *loginIDKey, NSString *newLoginId){
        if ([self.identifier isValidForLogin:loginIDKey value:newLoginId]) {
            [self.identifier loginWithKey:loginIDKey loginId:newLoginId];
            // 传入的 newLoginId 为原始值，因此在这里做赋值时需要检查是否需要拼接
            if ([loginIDKey isEqualToString:kHNIdentitiesLoginId]) {
                object.loginId = newLoginId;
            } else {
                object.loginId = [NSString stringWithFormat:@"%@%@%@", loginIDKey, kHNLoginIdSpliceKey, newLoginId];
            }
            [self identifyTrackWithEventObject:object];
        }
    };

    NSString *distinctId = object.distinctId;

    if (!identities) {
        // 2.0 版本逻辑，保持不变
        loginBlock(self.identifier.loginIDKey, distinctId);
        return;
    }
    NSString *newLoginId = identities[self.identifier.loginIDKey];

    NSMutableArray *array = [[distinctId componentsSeparatedByString:kHNLoginIdSpliceKey] mutableCopy];
    NSString *key = array.firstObject;
    // 移除 firstObject 的 loginIDKey，然后拼接后续的内容为 loginId
    [array removeObjectAtIndex:0];
    NSString *value = [array componentsJoinedByString:kHNLoginIdSpliceKey];
    NSSet *validKeys = [identities keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return [obj isEqualToString:distinctId];
    }];
    if (newLoginId) {
        loginBlock(self.identifier.loginIDKey, newLoginId);
    } else if ([identities[key] isEqualToString:value]) {
        // 当前 H5 的 distinct_id 是 key+value 拼接格式的，通过截取得到 loginIDKey 和 loginId
        loginBlock(key, value);
    } else if (validKeys.count == 1) {
        // 当前 H5 的登录 ID 不是拼接格式的，则直接从 identities 中查找对应的 loginIDKey，只存在一个 key 时作为 loginIDKey
        loginBlock(validKeys.anyObject, distinctId);
    } else {
        // 当 identities 中无法获取到登录 ID 时，只触发事件不进行 loginId 处理
        [self identifyTrackWithEventObject:object];
    }
}

@end
