//
// HNValidator.h
// HinaDataSDK
//
// Created by hina on 2022/2/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define HNPropertyError(errorCode, fromat, ...) \
    [NSError errorWithDomain:@"HinaDataErrorDomain" \
                        code:errorCode \
                    userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:fromat,##__VA_ARGS__]}] \


typedef NS_ENUM(NSUInteger, HNValidatorError) {
    HNValidatorErrorNil = 20001,
    HNValidatorErrorNotString,
    HNValidatorErrorEmpty,
    HNValidatorErrorRegexInit,
    HNValidatorErrorInvalid,
    HNValidatorErrorOverflow,
};

@interface HNValidator : NSObject

+ (BOOL)isValidString:(NSString *)string;

+ (BOOL)isValidDictionary:(NSDictionary *)dictionary;

+ (BOOL)isValidArray:(NSArray *)array;

+ (BOOL)isValidData:(NSData *)data;

/// 校验事件名或参数名是否有效
+ (void)validKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable * _Nullable)error;

//保留字校验
+ (void)reservedKeywordCheckForObject:(NSString *)object error:(NSError *__autoreleasing  _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
