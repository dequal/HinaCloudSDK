//
// HNEncryptManager.m
// HinaDataSDK
//
// Created by hina on 2022/11/25.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNEncryptManager.h"
#import "HNValidator.h"
#import "HNURLUtils.h"
#import "HNAlertController.h"
#import "HNStoreManager.h"
#import "HNJSONUtil.h"
#import "HNGzipUtility.h"
#import "HNLog.h"
#import "HNRSAPluginEncryptor.h"
#import "HNECCPluginEncryptor.h"
#import "HNConfigOptions+Encrypt.h"
#import "HNSecretKey.h"
#import "HNSecretKeyFactory.h"
#import "HNConstants+Private.h"

static NSString * const kHNEncryptSecretKey = @"HNEncryptSecretKey";

@interface HNConfigOptions (Private)

@property (atomic, strong, readonly) NSMutableArray *encryptors;

@end

@interface HNEncryptManager ()

/// 当前使用的加密插件
@property (nonatomic, strong) id<HNEncryptProtocol> encryptor;

/// 当前支持的加密插件列表
@property (nonatomic, copy) NSArray<id<HNEncryptProtocol>> *encryptors;

/// 已加密过的对称秘钥内容
@property (nonatomic, copy) NSString *encryptedSymmetricKey;

/// 非对称加密器的公钥（RSA/ECC 的公钥）
@property (nonatomic, strong) HNSecretKey *secretKey;

/// 防止 RSA 加密时卡住主线程, 所以新建串行队列处理
@property (nonatomic, strong) dispatch_queue_t encryptQueue;

@end

@implementation HNEncryptManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNEncryptManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNEncryptManager alloc] init];
        manager.encryptQueue = dispatch_queue_create("cn.hinadata.HNEncryptManagerEncryptQueue", DISPATCH_QUEUE_SERIAL);
    });
    return manager;
}

#pragma mark - HNModuleProtocol

- (void)setEnable:(BOOL)enable {
    _enable = enable;

    if (enable) {
        dispatch_async(self.encryptQueue, ^{
            [self updateEncryptor];
        });
    }
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    _configOptions = configOptions;
    if (configOptions.enableEncrypt) {
        NSAssert((configOptions.saveSecretKey && configOptions.loadSecretKey) || (!configOptions.saveSecretKey && !configOptions.loadSecretKey), @"Block saveSecretKey and loadSecretKey need to be fully implemented or not implemented at all.");
    }

    NSMutableArray *encryptors = [NSMutableArray array];

    // 当 ECC 加密库未集成时，不注册 ECC 加密插件
    if ([HNECCPluginEncryptor isAvaliable]) {
        [encryptors addObject:[[HNECCPluginEncryptor alloc] init]];
    }
    [encryptors addObject:[[HNRSAPluginEncryptor alloc] init]];
    [encryptors addObjectsFromArray:configOptions.encryptors];
    self.encryptors = encryptors;
    self.enable = configOptions.enableEncrypt;
}

#pragma mark - HNOpenURLProtocol

- (BOOL)canHandleURL:(nonnull NSURL *)url {
    return [url.host isEqualToString:@"encrypt"];
}

- (BOOL)handleURL:(nonnull NSURL *)url {
    NSString *message = HNLocalizedString(@"HNEncryptNotEnabled");

    if (self.enable) {
        NSDictionary *paramDic = [HNURLUtils queryItemsWithURL:url];
        NSString *urlVersion = paramDic[@"v"];

        // url 中的 key 为 encode 之后的，这里做 decode
        NSString *urlKey = [paramDic[@"key"] stringByRemovingPercentEncoding];

        if ([HNValidator isValidString:urlVersion] && [HNValidator isValidString:urlKey]) {
            HNSecretKey *secretKey = [self loadCurrentSecretKey];
            NSString *loadVersion = [@(secretKey.version) stringValue];

            // 这里为了兼容新老版本下发的 EC 秘钥中 URL key 前缀和本地保存的 EC 秘钥前缀不一致的问题，都统一删除 EC 前缀后比较内容
            NSString *currentKey = [secretKey.key hasPrefix:kHNEncryptECCPrefix] ? [secretKey.key substringFromIndex:kHNEncryptECCPrefix.length] : secretKey.key;
            NSString *decodeKey = [urlKey hasPrefix:kHNEncryptECCPrefix] ? [urlKey substringFromIndex:kHNEncryptECCPrefix.length] : urlKey;

            if ([loadVersion isEqualToString:urlVersion] && [currentKey isEqualToString:decodeKey]) {
                NSString *asymmetricType = [paramDic[@"asymmetricEncryptType"] stringByRemovingPercentEncoding];
                NSString *symmetricType = [paramDic[@"symmetricEncryptType"] stringByRemovingPercentEncoding];
                BOOL typeMatched = [secretKey.asymmetricEncryptType isEqualToString:asymmetricType] &&
                [secretKey.symmetricEncryptType isEqualToString:symmetricType];
                // 这里为了兼容老版本 HN 未下发秘钥类型，当某一个类型不存在时即当做老版本 HN 处理
                if (!asymmetricType || !symmetricType || typeMatched) {
                    message = HNLocalizedString(@"HNEncryptKeyVerificationPassed");
                } else {
                    message = [NSString stringWithFormat:HNLocalizedString(@"HNEncryptKeyTypeVerificationFailed"), symmetricType, asymmetricType, secretKey.symmetricEncryptType, secretKey.asymmetricEncryptType];
                }
            } else if (![HNValidator isValidString:currentKey]) {
                message = HNLocalizedString(@"HNEncryptAppKeyEmpty");
            } else {
                message = [NSString stringWithFormat:HNLocalizedString(@"HNEncryptKeyVersionVerificationFailed"), urlVersion, loadVersion];
            }
        } else {
            message = HNLocalizedString(@"HNEncryptSelectedKeyInvalid");
        }
    }

    HNAlertController *alertController = [[HNAlertController alloc] initWithTitle:nil message:message preferredStyle:HNAlertControllerStyleAlert];
    [alertController addActionWithTitle:HNLocalizedString(@"HNAlertOK") style:HNAlertActionStyleDefault handler:nil];
    [alertController show];
    return YES;
}

#pragma mark - HNEncryptModuleProtocol
- (BOOL)hasSecretKey {
    // 当可以获取到秘钥时，不需要强制性触发远程配置请求秘钥
    HNSecretKey *sccretKey = [self loadCurrentSecretKey];
    return (sccretKey.key.length > 0);
}

- (NSDictionary *)encryptJSONObject:(id)obj {
    @try {
        if (!obj) {
            HNLogDebug(@"Enable encryption but the input obj is invalid!");
            return nil;
        }

        if (!self.encryptor) {
            HNLogDebug(@"Enable encryption but the secret key is invalid!");
            return nil;
        }

        if (![self encryptSymmetricKey]) {
            HNLogDebug(@"Enable encryption but encrypt symmetric key is failed!");
            return nil;
        }

        // 使用 gzip 进行压缩
        NSData *jsonData = [HNJSONUtil dataWithJSONObject:obj];
        NSData *zippedData = [HNGzipUtility gzipData:jsonData];

        // 加密数据
        NSString *encryptedString =  [self.encryptor encryptEvent:zippedData];
        if (![HNValidator isValidString:encryptedString]) {
            return nil;
        }

        // 封装加密的数据结构
        NSMutableDictionary *secretObj = [NSMutableDictionary dictionary];
        secretObj[@"pkv"] = @(self.secretKey.version);
        secretObj[@"ekey"] = self.encryptedSymmetricKey;
        secretObj[@"payload"] = encryptedString;
        return [NSDictionary dictionaryWithDictionary:secretObj];
    } @catch (NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
        return nil;
    }
}

- (BOOL)encryptSymmetricKey {
    if (self.encryptedSymmetricKey) {
        return YES;
    }
    NSString *publicKey = self.secretKey.key;
    self.encryptedSymmetricKey = [self.encryptor encryptSymmetricKeyWithPublicKey:publicKey];
    return self.encryptedSymmetricKey != nil;
}

#pragma mark - handle remote config for secret key
- (void)handleEncryptWithConfig:(NSDictionary *)encryptConfig {
    dispatch_async(self.encryptQueue, ^{
        [self updateEncryptorWithConfig:encryptConfig];
    });
}

- (void)updateEncryptorWithConfig:(NSDictionary *)encryptConfig {
    if (!encryptConfig) {
        return;
    }

    // 加密插件化 2.0 新增字段，下发秘钥信息不可用时，继续走 1.0 逻辑
    HNSecretKey *secretKey = [HNSecretKeyFactory createSecretKeyByVersion2:encryptConfig[@"key_v2"]];
    if (![self encryptorWithSecretKey:secretKey]) {
        // 加密插件化 1.0 秘钥信息
        secretKey = [HNSecretKeyFactory createSecretKeyByVersion1:encryptConfig[@"key"]];
    }

    //当前秘钥没有对应的加密器
    if (![self encryptorWithSecretKey:secretKey]) {
        return;
    }
    // 存储请求的公钥
    [self saveRequestSecretKey:secretKey];
    // 更新加密构造器
    [self updateEncryptor];
}

- (void)updateEncryptor {
    @try {
        HNSecretKey *secretKey = [self loadCurrentSecretKey];
        if (![HNValidator isValidString:secretKey.key]) {
            return;
        }

        if (secretKey.version <= 0) {
            return;
        }

        // 返回的密钥与已有的密钥一样则不需要更新
        if ([self isSameSecretKey:self.secretKey newSecretKey:secretKey]) {
            return;
        }

        id<HNEncryptProtocol> encryptor = [self filterEncrptor:secretKey];
        if (!encryptor) {
            return;
        }

        NSString *encryptedSymmetricKey = [encryptor encryptSymmetricKeyWithPublicKey:secretKey.key];
        if ([HNValidator isValidString:encryptedSymmetricKey]) {
            // 更新密钥
            self.secretKey = secretKey;
            // 更新加密插件
            self.encryptor = encryptor;
            // 重新生成加密插件的对称密钥
            self.encryptedSymmetricKey = encryptedSymmetricKey;
        }
    } @catch (NSException *exception) {
        HNLogError(@"%@ error: %@", self, exception);
    }
}

- (BOOL)isSameSecretKey:(HNSecretKey *)currentSecretKey newSecretKey:(HNSecretKey *)newSecretKey {
    if (currentSecretKey.version != newSecretKey.version) {
        return NO;
    }
    if (![currentSecretKey.key isEqualToString:newSecretKey.key]) {
        return NO;
    }
    if (![currentSecretKey.symmetricEncryptType isEqualToString:newSecretKey.symmetricEncryptType]) {
        return NO;
    }
    if (![currentSecretKey.asymmetricEncryptType isEqualToString:newSecretKey.asymmetricEncryptType]) {
        return NO;
    }
    return YES;
}

- (id<HNEncryptProtocol>)filterEncrptor:(HNSecretKey *)secretKey {
    id<HNEncryptProtocol> encryptor = [self encryptorWithSecretKey:secretKey];
    if (!encryptor) {
        NSString *format = @"\n You used a [%@] key, but the corresponding encryption plugin is not registered. \n • If you are using EC+AES or SM2+SM4 encryption, please check that the 'HinaDataEncrypt' module is correctly integrated and that the corresponding encryption plugin is registered. \n";
        NSString *type = [NSString stringWithFormat:@"%@+%@", secretKey.asymmetricEncryptType, secretKey.symmetricEncryptType];
        NSString *message = [NSString stringWithFormat:format, type];
        NSAssert(NO, message);
        return nil;
    }
    return encryptor;
}

- (id<HNEncryptProtocol>)encryptorWithSecretKey:(HNSecretKey *)secretKey {
    if (!secretKey) {
        return nil;
    }
    __block id<HNEncryptProtocol> encryptor;
    [self.encryptors enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id<HNEncryptProtocol> obj, NSUInteger idx, BOOL *stop) {
        BOOL isSameAsymmetricType = [[obj asymmetricEncryptType] isEqualToString:secretKey.asymmetricEncryptType];
        BOOL isSameSymmetricType = [[obj symmetricEncryptType] isEqualToString:secretKey.symmetricEncryptType];
        // 当非对称加密类型和对称加密类型都匹配一致时，返回对应加密器
        if (isSameAsymmetricType && isSameSymmetricType) {
            encryptor = obj;
            *stop = YES;
        }
    }];
    return encryptor;
}

#pragma mark - archive/unarchive secretKey
- (void)saveRequestSecretKey:(HNSecretKey *)secretKey {
    if (!secretKey) {
        return;
    }

    void (^saveSecretKey)(HNSecretKey *) = self.configOptions.saveSecretKey;
    if (saveSecretKey) {
        // 通过用户的回调保存公钥
        saveSecretKey(secretKey);

        [[HNStoreManager sharedInstance] removeObjectForKey:kHNEncryptSecretKey];

        HNLogDebug(@"Save secret key by saveSecretKey callback, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
    } else {
        // 存储到本地
        NSData *secretKeyData = [NSKeyedArchiver archivedDataWithRootObject:secretKey];
        [[HNStoreManager sharedInstance] setObject:secretKeyData forKey:kHNEncryptSecretKey];

        HNLogDebug(@"Save secret key by localSecretKey, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
    }
}

- (HNSecretKey *)loadCurrentSecretKey {
    HNSecretKey *secretKey = nil;

    HNSecretKey *(^loadSecretKey)(void) = self.configOptions.loadSecretKey;
    if (loadSecretKey) {
        // 通过用户的回调获取公钥
        secretKey = loadSecretKey();

        if (secretKey) {
            HNLogDebug(@"Load secret key from loadSecretKey callback, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
        } else {
            HNLogDebug(@"Load secret key from loadSecretKey callback failed!");
        }
    } else {
        // 通过本地获取公钥
        id secretKeyData = [[HNStoreManager sharedInstance] objectForKey:kHNEncryptSecretKey];
        if ([HNValidator isValidData:secretKeyData]) {
            secretKey = [NSKeyedUnarchiver unarchiveObjectWithData:secretKeyData];
        }

        if (secretKey) {
            HNLogDebug(@"Load secret key from localSecretKey, pkv : %ld, public_key : %@", (long)secretKey.version, secretKey.key);
        } else {
            HNLogDebug(@"Load secret key from localSecretKey failed!");
        }
    }
    return secretKey;
}

@end
