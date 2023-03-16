//
// HNDatabaseInterceptor.m
// HinaDataSDK
//
// Created by  hina on 2022/5/17.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNDatabaseInterceptor.h"
#import "HNFileStorePlugin.h"

@interface HNDatabaseInterceptor()

@property (nonatomic, strong, readwrite) HNEventStore *eventStore;

@end

@implementation HNDatabaseInterceptor

+ (instancetype)interceptorWithParam:(NSDictionary *)param {
    HNDatabaseInterceptor *interceptor = [super interceptorWithParam:param];
    NSString *fileName = param[kHNDatabaseNameKey] ?: kHNDatabaseDefaultFileName;
    NSString *path = [HNFileStorePlugin filePath:fileName];
    interceptor.eventStore = [HNEventStore eventStoreWithFilePath:path];

    return interceptor;
}


@end
