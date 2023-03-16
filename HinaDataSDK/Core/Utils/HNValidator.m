//
// HNValidator.m
// HinaDataSDK
//
// Created by hina on 2022/2/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNValidator.h"
#import "HNConstants+Private.h"
#import "HNLog.h"
#import "HinaDataSDK+Private.h"

static NSRegularExpression *regexForValidKey;
static NSString *const kHNProperNameValidateRegularExpression = @"^((?!^distinct_id$|^original_id$|^time$|^properties$|^id$|^first_id$|^second_id$|^users$|^events$|^event$|^user_id$|^date$|^datetime$|^user_tag.*|^user_group.*)[a-zA-Z_$][a-zA-Z\\d_$]*)$";


@implementation HNValidator

+ (BOOL)isValidString:(NSString *)string {
    return ([string isKindOfClass:[NSString class]] && ([string length] > 0));
}

+ (BOOL)isValidArray:(NSArray *)array {
    return ([array isKindOfClass:[NSArray class]] && ([array count] > 0));
}

+ (BOOL)isValidDictionary:(NSDictionary *)dictionary {
    return ([dictionary isKindOfClass:[NSDictionary class]] && ([dictionary count] > 0));
}

+ (BOOL)isValidData:(NSData *)data {
    return ([data isKindOfClass:[NSData class]] && ([data length] > 0));
}

+ (void)validKey:(NSString *)key error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    if (!key) {
        *error = HNPropertyError(HNValidatorErrorNil, @"Property key or Event name should not be nil");
        return;
    }

    if (![key isKindOfClass:[NSString class]]) {
        *error = HNPropertyError(HNValidatorErrorNotString, @"Property key or Event name must be string, not %@", [key class]);
        return;
    }

    if (key.length == 0) {
        *error = HNPropertyError(HNValidatorErrorEmpty, @"Property key or Event name is empty");
        return;
    }

    NSError *tempError = nil;
    [self reservedKeywordCheckForObject:key error:&tempError];
    if (tempError) {
        *error = tempError;
        return;
    }
    
    if (key.length > kHNEventNameMaxLength) {
        *error = HNPropertyError(HNValidatorErrorOverflow, @"Property key or Event name %@'s length is longer than %ld", key, kHNEventNameMaxLength);
        return;
    }
    *error = nil;
}

+ (void)reservedKeywordCheckForObject:(NSString *)object error:(NSError *__autoreleasing  _Nullable *)error {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regexForValidKey = [NSRegularExpression regularExpressionWithPattern:kHNProperNameValidateRegularExpression options:NSRegularExpressionCaseInsensitive error:nil];
    });

    if (!regexForValidKey) {
        *error = HNPropertyError(HNValidatorErrorRegexInit, @"Property Key validate regular expression init failed, please check the regular expression's syntax");
        return;
    }

    // 属性名通过正则表达式匹配，比使用谓词效率更高
    NSRange range = NSMakeRange(0, object.length);
    if ([regexForValidKey numberOfMatchesInString:object options:0 range:range] < 1) {
        *error = HNPropertyError(HNValidatorErrorInvalid, @"Property Key or Event name: [%@] is invalid.", object);
        return;
    }
}
@end
