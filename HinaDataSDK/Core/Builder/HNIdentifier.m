//
// HNIdentifier.m
// HinaDataSDK
//
// Created by hina on 2022/2/17.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNIdentifier.h"
#import "HNConstants+Private.h"
#import "HNStoreManager.h"
#import "HNValidator.h"
#import "HNLog.h"
#import "HinaDataSDK+Private.h"
#import "HNLimitKeyManager.h"

#if TARGET_OS_IOS
#import "HNKeyChainItemWrapper.h"
#import <UIKit/UIKit.h>
#endif

NSString * const kHNIdentities = @"com.hinadata.identities";
NSString * const kHNIdentitiesLoginId = @"H_identity_login_id";
NSString * const kHNIdentitiesAnonymousId = @"H_identity_anonymous_id";
NSString * const kHNIdentitiesCookieId = @"H_identity_cookie_id";

#if TARGET_OS_OSX
NSString * const kHNIdentitiesOldUniqueID = @"H_mac_serial_id";
NSString * const kHNIdentitiesUniqueID = @"H_identity_mac_serial_id";
NSString * const kHNIdentitiesUUID = @"H_identity_mac_uuid";
#else
NSString * const kHNIdentitiesUniqueID = @"H_identity_idfv";
NSString * const kHNIdentitiesUUID = @"H_identity_ios_uuid";
#endif

NSString * const kHNLoginIDKey = @"com.hinadata.loginidkey";
NSString * const kHNIdentitiesCacheType = @"Base64:";

NSString * const kHNLoginIdSpliceKey = @"+";

@interface HNIdentifier ()

@property (nonatomic, strong) dispatch_queue_t queue;

@property (nonatomic, copy, readwrite) NSString *loginId;
@property (nonatomic, copy, readwrite) NSString *anonymousId;
@property (nonatomic, copy, readwrite) NSString *loginIDKey;

// ID-Mapping 3.0 拼接前客户传入的原始 LoginID
@property (nonatomic, copy) NSString *originalLoginId;

@property (nonatomic, copy, readwrite) NSDictionary *identities;
@property (nonatomic, copy) NSDictionary *removedIdentity;

@end

@implementation HNIdentifier

#pragma mark - Life Cycle

- (instancetype)initWithQueue:(dispatch_queue_t)queue {
    self = [super init];
    if (self) {
        _queue = queue;
        dispatch_async(_queue, ^{
            // 获取 self.identities 需要判断当前本地文件是否存在 anonymousId
            // 获取 self.anonymousId 会写入本地文件，因此需要先获取 self.identities
            self.loginIDKey = [self unarchiveLoginIDKey];
            self.identities = [self unarchiveIdentitiesWithKey:self.loginIDKey];
            self.anonymousId = [self unarchiveAnonymousId];
            NSString *cacheLoginId = [[HNStoreManager sharedInstance] objectForKey:kHNEventLoginId];
            self.originalLoginId = cacheLoginId;
            if ([self.loginIDKey isEqualToString:kHNIdentitiesLoginId]) {
                self.loginId = cacheLoginId;
            } else {
                self.loginId = [NSString stringWithFormat:@"%@%@%@", self.loginIDKey, kHNLoginIdSpliceKey, cacheLoginId];
            }
        });
    }
    return self;
}

#pragma mark - Public Methods

- (BOOL)identify:(NSString *)anonymousId {
    if (![anonymousId isKindOfClass:[NSString class]]) {
        HNLogError(@"AnonymousId must be string");
        return NO;
    }
    if (anonymousId.length == 0) {
        HNLogError(@"AnonymousId is empty");
        return NO;
    }

    if ([anonymousId length] > kHNPropertyValueMaxLength) {
        HNLogWarn(@"AnonymousId: %@'s length is longer than %ld", anonymousId, kHNPropertyValueMaxLength);
    }

    if ([anonymousId isEqualToString:self.anonymousId]) {
        return NO;
    }
    
    [self updateAnonymousId:anonymousId];
    return YES;
}

- (void)archiveAnonymousId:(NSString *)anonymousId {
    [[HNStoreManager sharedInstance] setObject:anonymousId forKey:kHNEventDistinctId];
#if TARGET_OS_IOS
    [HNKeyChainItemWrapper saveUdid:anonymousId];
#endif
}

- (void)resetAnonymousId {
    NSString *anonymousId = [HNIdentifier hardwareID];
    [self updateAnonymousId:anonymousId];
}

- (void)updateAnonymousId:(NSString *)anonymousId {
    // 异步任务设置匿名 ID
    dispatch_async(self.queue, ^{
        self.anonymousId = anonymousId;
        [self archiveAnonymousId:anonymousId];
    });
}

- (BOOL)isValidLoginId:(NSString *)loginId {
    if (![loginId isKindOfClass:[NSString class]]) {
        HNLogError(@"LoginId must be string");
        return NO;
    }
    if (loginId.length == 0) {
        HNLogError(@"LoginId is empty");
        return NO;
    }
    if ([loginId length] > kHNPropertyValueMaxLength) {
        HNLogWarn(@"LoginId: %@'s length is longer than %ld", loginId, kHNPropertyValueMaxLength);
    }
    // 为了避免将匿名 ID 作为 LoginID 传入
    if ([loginId isEqualToString:self.anonymousId]) {
        return NO;
    }
    return YES;
}

- (BOOL)isValidLoginIDKey:(NSString *)key {
    NSError *error = nil;
    [HNValidator validKey:key error:&error];
    if (error) {
        HNLogError(@"%@",error.localizedDescription);
        if (error.code != HNValidatorErrorOverflow) {
            return NO;
        }
    }
    if ([self isDeviceIDKey:key] || [self isAnonymousIDKey:key]) {
        HNLogError(@"LoginIDKey [ %@ ] is invalid", key);
        return NO;
    }
    return YES;
}

- (BOOL)isValidForLogin:(NSString *)key value:(NSString *)value {
    if (![self isValidLoginIDKey:key]) {
        return NO;
    }
    if (![self isValidLoginId:value]) {
        return NO;
    }
    // 当 loginIDKey 和 loginId 均未发生变化时，不需要触发事件
    if ([self.loginIDKey isEqualToString:key] && [self.originalLoginId isEqualToString:value]) {
        return NO;
    }
    return  YES;
}

- (void)loginWithKey:(NSString *)key loginId:(NSString *)loginId {
    [self updateLoginInfo:key loginId:loginId];
    [self bindIdentity:key value:loginId];
}

- (void)updateLoginInfo:(NSString *)loginIDKey loginId:(NSString *)loginId {
    dispatch_async(self.queue, ^{
        if ([loginIDKey isEqualToString:kHNIdentitiesLoginId]) {
            self.loginId = loginId;
        } else {
            self.loginId = [NSString stringWithFormat:@"%@%@%@", loginIDKey, kHNLoginIdSpliceKey,loginId];
        }
        self.originalLoginId = loginId;
        self.loginIDKey = loginIDKey;
        // 本地缓存的 login_id 值为原始值，在初始化时处理拼接逻辑
        [[HNStoreManager sharedInstance] setObject:loginId forKey:kHNEventLoginId];
        // 登录时本地保存当前的 loginIDKey 字段，字段存在时表示 v3.0 版本 SDK 已进行过登录
        [[HNStoreManager sharedInstance] setObject:loginIDKey forKey:kHNLoginIDKey];
    });
}

- (void)logout {
    [self clearLoginInfo];
    [self resetIdentities];
}

- (void)clearLoginInfo {
    dispatch_async(self.queue, ^{
        self.loginId = nil;
        self.originalLoginId = nil;
        self.loginIDKey = kHNIdentitiesLoginId;
        [[HNStoreManager sharedInstance] removeObjectForKey:kHNEventLoginId];
        // 退出登录时清除本地保存的 loginIDKey 字段，字段不存在时表示 v3.0 版本 SDK 已退出登录
        [[HNStoreManager sharedInstance] removeObjectForKey:kHNLoginIDKey];
    });
}

#if TARGET_OS_IOS
+ (NSString *)idfa {
    NSString *idfa = HNLimitKeyManager.idfa;
    if ([idfa isEqualToString:@""]) {
        return nil;
    } else if (idfa.length > 0) {
        return idfa;
    }

    Class cla = NSClassFromString(@"HNIDFAHelper");
    SEL sel = NSSelectorFromString(@"idfa");
    if ([cla respondsToSelector:sel]) {
        NSString * (*idfaIMP)(id, SEL) = (NSString * (*)(id, SEL))[cla methodForSelector:sel];
        if (idfaIMP) {
            return idfaIMP(cla, sel);
        }
    }
    return nil;
}

+ (NSString *)idfv {
    NSString *idfv = HNLimitKeyManager.idfv;
    if ([idfv isEqualToString:@""]) {
        return nil;
    } else if (idfv.length > 0) {
        return idfv;
    }

    return [UIDevice currentDevice].identifierForVendor.UUIDString;
}
#elif TARGET_OS_OSX
/// mac SerialNumber（序列号）作为设备标识
+ (NSString *)serialNumber {
    io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,IOServiceMatching("IOPlatformExpertDevice"));
    CFStringRef serialNumberRef = NULL;
    if (platformExpert) {
        serialNumberRef = IORegistryEntryCreateCFProperty(platformExpert,CFSTR(kIOPlatformSerialNumberKey),kCFAllocatorDefault, 0);
        IOObjectRelease(platformExpert);
    }
    NSString *serialNumberString = nil;
    if (serialNumberRef) {
        serialNumberString = [NSString stringWithString:(__bridge NSString *)serialNumberRef];
        CFRelease(serialNumberRef);
    }
    return serialNumberString;
}
#endif


+ (NSString *)hardwareID {
    NSString *distinctId = nil;
#if TARGET_OS_IOS
    distinctId = [self idfa];
    // 没有IDFA，则使用IDFV
    if (!distinctId) {
        distinctId = [self idfv];
    }
#elif TARGET_OS_OSX
    distinctId = [self serialNumber];
#endif

    // 如果都没取到，则使用UUID
    if (!distinctId) {
        HNLogDebug(@"%@ error getting device identifier: falling back to uuid", self);
        distinctId = [NSUUID UUID].UUIDString;
    }
    return distinctId;
}

#pragma mark – Private Methods

- (NSString *)unarchiveAnonymousId {
    NSString *anonymousId = [[HNStoreManager sharedInstance] objectForKey:kHNEventDistinctId];

#if TARGET_OS_IOS
    NSString *distinctIdInKeychain = [HNKeyChainItemWrapper saUdid];
    if (distinctIdInKeychain.length > 0) {
        if (![anonymousId isEqualToString:distinctIdInKeychain]) {
            // 保存 Archiver
            [[HNStoreManager sharedInstance] setObject:distinctIdInKeychain forKey:kHNEventDistinctId];
        }
        anonymousId = distinctIdInKeychain;
    } else {
        if (anonymousId.length == 0) {
            anonymousId = [HNIdentifier hardwareID];
            [self archiveAnonymousId:anonymousId];
        } else {
            //保存 KeyChain
            [HNKeyChainItemWrapper saveUdid:anonymousId];
        }
    }
#else
    if (anonymousId.length == 0) {
        anonymousId = [HNIdentifier hardwareID];
        [self archiveAnonymousId:anonymousId];
    }
#endif

    return anonymousId;
}

#pragma mark – Getters and Setters
- (NSString *)loginId {
    __block NSString *loginId;
    hinadata_dispatch_safe_sync(self.queue, ^{
        loginId = _loginId;
    });
    return loginId;
}

- (NSString *)originalLoginId {
    __block NSString *originalLoginId;
    hinadata_dispatch_safe_sync(self.queue, ^{
        originalLoginId = _originalLoginId;
    });
    return originalLoginId;
}

- (NSString *)anonymousId {
    __block NSString *anonymousId;
    hinadata_dispatch_safe_sync(self.queue, ^{
        if (!_anonymousId) {
            [self resetAnonymousId];
        }
        anonymousId = _anonymousId;
    });
    return anonymousId;
}

- (NSString *)distinctId {
    __block NSString *distinctId = nil;
    dispatch_block_t block = ^{
        distinctId = self.loginId;
        if (distinctId.length == 0) {
            distinctId = self.anonymousId;
        }
    };
    hinadata_dispatch_safe_sync(self.queue, block);
    return distinctId;
}

- (NSDictionary *)identities {
    __block NSDictionary *identities;
    hinadata_dispatch_safe_sync(self.queue, ^{
        identities = _identities;
    });
    return identities;
}

- (NSString *)loginIDKey {
    __block NSString *loginIDKey;
    hinadata_dispatch_safe_sync(self.queue, ^{
        loginIDKey = _loginIDKey;
    });
    return loginIDKey;
}

- (NSDictionary *)removedIdentity {
    __block NSDictionary *removedIdentity;
    hinadata_dispatch_safe_sync(self.queue, ^{
        removedIdentity = _removedIdentity;
    });
    return removedIdentity;
}

#pragma mark - Identities
- (NSDictionary *)mergeH5Identities:(NSDictionary *)identities eventType:(HNEventType)eventType {
    if (eventType & HNEventTypeUnbind) {
        NSString *key = identities.allKeys.firstObject;
        if (![self isValidForUnbind:key value:identities[key]]) {
            return @{};
        }
        [self unbindIdentity:key value:identities[key]];
        return identities;
    }

    NSMutableDictionary *newIdentities = [NSMutableDictionary dictionaryWithDictionary:identities];
    // 移除 H5 事件 identities 中的保留 ID，不允许 H5 绑定保留 ID
    [newIdentities removeObjectsForKeys:@[kHNIdentitiesUniqueID, kHNIdentitiesUUID]];
    [newIdentities addEntriesFromDictionary:self.identities];

    // 当 identities 不存在（ 2.0 版本）或 identities 中包含自定义 login_id （3.0 版本）时
    // 即表示有效登录，需要重置 identities 内容
    BOOL reset = (!identities || identities[self.loginIDKey]);
    if ((eventType & HNEventTypeSignup) && reset) {
        // 当前逻辑需要在调用 login 后执行才是有效的，重置 identities 时需要使用 login_id
        // 触发登录事件切换用户时，清空后续事件中的已绑定参数
        [self resetIdentities];
    }

    // 当为绑定事件时，Native 需要把绑定的业务 ID 持久化
    if ((eventType & HNEventTypeBind)) {
        dispatch_async(self.queue, ^{
            NSMutableDictionary *archive = [newIdentities mutableCopy];
            [archive removeObjectForKey:kHNIdentitiesCookieId];
            self.identities = archive;
            [self archiveIdentities:archive];
        });
    }
    return newIdentities;
}

- (BOOL)isDeviceIDKey:(NSString *)key {
    return ([key isEqualToString:kHNIdentitiesUniqueID] ||
            [key isEqualToString:kHNIdentitiesUUID]
       #if TARGET_OS_OSX
            || [key isEqualToString:kHNIdentitiesOldUniqueID]
       #endif
            );
}

- (BOOL)isAnonymousIDKey:(NSString *)key {
    // H_identity_anonymous_id 为兼容 2.0 identify() 的产物，也不允许客户绑定与解绑
    return [key isEqualToString:kHNIdentitiesAnonymousId];
}

- (BOOL)isLoginIDKey:(NSString *)key {
    // H_identity_login_id 为业务唯一标识，不允许客户绑定或解绑，只能通过 login 接口关联
    return [key isEqualToString:kHNIdentitiesLoginId];
}

- (BOOL)isValidForBind:(NSString *)key value:(NSString *)value {
    if (![key isKindOfClass:NSString.class]) {
        HNLogError(@"Key [%@] must be string", key);
        return NO;
    }
    if (key.length <= 0) {
        HNLogError(@"Key is empty");
        return NO;
    }
    if ([self isDeviceIDKey:key] || [self isAnonymousIDKey:key] || [self isLoginIDKey:key]) {
        HNLogError(@"Key [ %@ ] is invalid", key);
        return NO;
    }
    if ([key isEqualToString:self.loginIDKey]) {
        HNLogError(@"Key [ %@ ] is invalid", key);
        return NO;
    }
    return [self isValidIdentity:key value:value];
}

- (BOOL)isValidForUnbind:(NSString *)key value:(NSString *)value {
    if (![key isKindOfClass:NSString.class]) {
        HNLogError(@"Key [%@] must be string", key);
        return NO;
    }
    if (key.length <= 0) {
        HNLogError(@"Key is empty");
        return NO;
    }
    return [self isValidIdentity:key value:value];
}

- (BOOL)isValidIdentity:(NSString *)key value:(NSString *)value {
    NSError *error = nil;
    [HNValidator validKey:key error:&error];
    if (error) {
        HNLogError(@"%@",error.localizedDescription);
    }
    if (error && error.code != HNValidatorErrorOverflow) {
        return NO;
    }
    // 不允许绑定/解绑 H_identity_anonymous_id 和 H_identity_login_id
    if ([self isAnonymousIDKey:key] || [self isLoginIDKey:key]) {
        HNLogError(@"Key [ %@ ] is invalid", key);
        return NO;
    }
    if (!value) {
        HNLogError(@"bind or unbind value should not be nil");
        return NO;
    }
    if (![value isKindOfClass:[NSString class]]) {
        HNLogError(@"bind or unbind value should be string");
        return NO;
    }
    if (value.length == 0) {
        HNLogError(@"bind or unbind value should not be empty");
        return NO;
    }
    [value hinadata_propertyValueWithKey:key error:nil];
    return YES;
}

- (void)bindIdentity:(NSString *)key value:(NSString *)value {
    NSMutableDictionary *identities = [self.identities mutableCopy];
    identities[key] = value;
    dispatch_async(self.queue, ^{
        self.identities = identities;
        [self archiveIdentities:identities];
    });
}

- (void)unbindIdentity:(NSString *)key value:(NSString *)value {
    NSMutableDictionary *removed = [NSMutableDictionary dictionary];
    removed[key] = value;
    if (![value isEqualToString:self.identities[key]] || [self isDeviceIDKey:key]) {
        // 当 identities 中不存在需要解绑的字段时，不需要进行删除操作
        dispatch_async(self.queue, ^{
            self.removedIdentity = removed;
        });
        return;
    }

    // 当解绑自定义 loginIDKey 时，需要同步清除 2.0 的 login_id 信息
    NSString *result = [NSString stringWithFormat:@"%@%@%@", key, kHNLoginIdSpliceKey, value];
    if ([result isEqualToString:self.loginId]) {
        [self clearLoginInfo];
    }

    NSMutableDictionary *identities = [self.identities mutableCopy];
    [identities removeObjectForKey:key];
    dispatch_async(self.queue, ^{
        self.removedIdentity = removed;
        self.identities = identities;
        [self archiveIdentities:identities];
    });
}

- (void)resetIdentities {
    NSMutableDictionary *identities = [NSMutableDictionary dictionary];
    identities[kHNIdentitiesUniqueID] = self.identities[kHNIdentitiesUniqueID];
    identities[kHNIdentitiesUUID] = self.identities[kHNIdentitiesUUID];
    // 当 loginId 存在时需要添加 loginId
    identities[self.loginIDKey] = self.originalLoginId;
    dispatch_async(self.queue, ^{
        self.identities = identities;
        [self archiveIdentities:identities];
    });
}

- (NSDictionary *)identitiesWithEventType:(HNEventType)eventType {
    // 提前拷贝当前事件的 identities 内容，避免登录事件时被清空其他业务 ID
    NSDictionary *identities = [self.identities copy];

    if (eventType & HNEventTypeUnbind) {
        identities = [self.removedIdentity copy];
        self.removedIdentity = nil;
    }
    // 客户业务场景下切换用户后，需要清除其他已绑定业务 ID
    if (eventType & HNEventTypeSignup) {
        [self resetIdentities];
    }
    return identities;
}

- (NSString *)unarchiveLoginIDKey {
    NSString *content = [[HNStoreManager sharedInstance] objectForKey:kHNLoginIDKey];
    if (content.length < 1) {
        content = kHNIdentitiesLoginId;
        [[HNStoreManager sharedInstance] setObject:content forKey:kHNLoginIDKey];
    }
    return content;
}

- (NSDictionary *)unarchiveIdentitiesWithKey:(NSString *)loginIDKey {
    NSDictionary *cache = [self decodeIdentities];
    NSMutableDictionary *identities = [NSMutableDictionary dictionaryWithDictionary:cache];

    // SDK 取 IDFV 或 uuid 为设备唯一标识，已知情况下未发现获取不到 IDFV 的情况
    if (!identities[kHNIdentitiesUniqueID] && !identities[kHNIdentitiesUUID] ) {
        NSString *key = kHNIdentitiesUUID;
        NSString *value = [NSUUID UUID].UUIDString;
#if TARGET_OS_IOS
        if ([HNIdentifier idfv]) {
            key = kHNIdentitiesUniqueID;
            value = [HNIdentifier idfv];
        }
#elif TARGET_OS_OSX
        if ([HNIdentifier serialNumber]) {
            key = kHNIdentitiesUniqueID;
            value = [HNIdentifier serialNumber];
        }
#endif
        identities[key] = value;
    }

    NSString *loginId = [[HNStoreManager sharedInstance] objectForKey:kHNEventLoginId];
    // 本地存在 loginId 时表示 v2.0 版本为登录状态，可能需要将登录状态同步 v3.0 版本的 identities 中
    // 为了避免客户升级 v3.0 后又降级至 v2.0，然后又升级至 v3.0 版本的兼容问题，这里每次冷启动都处理一次

    // 当 v3.0 版本进行过登录操作时，本地一定会存在登录时使用的 loginIDKey 内容
    NSString *cachedKey = [[HNStoreManager sharedInstance] objectForKey:kHNLoginIDKey];
    if (loginId) {
        if (identities[cachedKey]) {
            // 场景：
            // v3.0 版本设置 loginIDKey 为 a_id 并进行登录 123, 降级至 v2.0 版本并重新登录 456, 再次升级至 v3.0 版本后 loginIDKey 仍为 a_id
            // 此时 identities 中存在 a_id 内容，需要更新 a_id 内容
            if (![identities[cachedKey] isEqualToString:loginId]) {
                // 当 identities 中 cachedKey 内容和 v2.0 版本 loginId 内容不一致时，表示登录用户发生了变化，需要更新 cachedKey 对应内容并清空其他所有业务 ID
                NSMutableDictionary *newIdentities = [NSMutableDictionary dictionary];
                newIdentities[kHNIdentitiesUniqueID] = identities[kHNIdentitiesUniqueID];
                newIdentities[kHNIdentitiesUUID] = identities[kHNIdentitiesUUID];
                // identities 中存在 cachedKey 内容时，只需要更新 cachedKey 对应的内容。
                newIdentities[cachedKey] = loginId;
                identities = newIdentities;
            }
        } else {
            // 场景：
            // v3.0 版本设置 loginIDKey 为 H_identity_login_id 且未进行登录, 降级至 v2.0 版本并重新登录 456, 再次升级至 v3.0 版本后 loginIDKey 仍为 H_identity_login_id
            // 此时 identities 中不存在 cacheKey 对应内容，表示 v3.0 版本未进行过登录操作。要将 v2.0 版本登录状态 { H_identity_login_id:456 } 同步至 v3.0 版本的 identities 中
            NSMutableDictionary *newIdentities = [NSMutableDictionary dictionary];
            newIdentities[kHNIdentitiesUniqueID] = identities[kHNIdentitiesUniqueID];
            newIdentities[kHNIdentitiesUUID] = identities[kHNIdentitiesUUID];
            newIdentities[loginIDKey] = loginId;
            identities = newIdentities;

            // 此时相当于进行登录操作，需要保存登录时设置的 loginIDKey 内容至本地文件中
            [[HNStoreManager sharedInstance] setObject:loginIDKey forKey:kHNLoginIDKey];
        }
    } else {
        if (identities[cachedKey]) {
            // 场景：v3.0 版本登录时，降级至 v2.0 版本并退出登录，然后再升级至 v3.0 版本
            // 此时 identities 中仍为登录状态，需要进行退出登录操作
            // 只需要保留 H_identity_idfv/H_identity_ios_uuid 和 H_identity_anonymous_id
            NSMutableDictionary *newIdentities = [NSMutableDictionary dictionary];
            newIdentities[kHNIdentitiesUniqueID] = identities[kHNIdentitiesUniqueID];
            newIdentities[kHNIdentitiesUUID] = identities[kHNIdentitiesUUID];
            identities = newIdentities;
        }
        // 当 v2.0 版本状态为未登录状态时，直接清空本地保存的 loginIDKey 文件内容
        // v3.0 版本清空本地保存的 loginIDKey 会在 logout 中处理
        [[HNStoreManager sharedInstance] removeObjectForKey:kHNLoginIDKey];
    }
#if TARGET_OS_OSX
        // 4.1.0 以后的版本将 H_mac_serial_id 替换为了 H_identity_mac_serial_id
        // 此处不考虑是否是用户绑定的 key, 直接移除
        if (identities[kHNIdentitiesOldUniqueID]) {
            [identities removeObjectForKey:kHNIdentitiesOldUniqueID];
        }
#endif
    // 每次强制更新一次本地 identities，触发部分业务场景需要更新本地内容
    [self archiveIdentities:identities];
    return identities;
}

- (NSDictionary *)decodeIdentities {
    NSString *content = [[HNStoreManager sharedInstance] objectForKey:kHNIdentities];
    if (![content isKindOfClass:NSString.class]) {
        return nil;
    }
    NSData *data;
    if ([content hasPrefix:kHNIdentitiesCacheType]) {
        NSString *value = [content substringFromIndex:kHNIdentitiesCacheType.length];
        data = [[NSData alloc] initWithBase64EncodedString:value options:NSDataBase64DecodingIgnoreUnknownCharacters];
    }
    if (!data) {
        return nil;
    }
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
}

- (void)archiveIdentities:(NSDictionary *)identities {
    if (!identities) {
        return;
    }

    @try {
        NSData *data = [NSJSONSerialization dataWithJSONObject:identities options:NSJSONWritingPrettyPrinted error:nil];
        NSString *base64Str = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
        NSString *result = [NSString stringWithFormat:@"%@%@",kHNIdentitiesCacheType, base64Str];
        [[HNStoreManager sharedInstance] setObject:result forKey:kHNIdentities];
    } @catch (NSException *exception) {
        HNLogError(@"%@", exception);
    }
}

@end
