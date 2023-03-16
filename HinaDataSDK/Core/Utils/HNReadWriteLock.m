//
// HNReadWriteLock.m
// HinaDataSDK
//
// Created by hina on 2022/5/21.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNReadWriteLock.h"
#import "HNValidator.h"

@interface HNReadWriteLock ()

@property (nonatomic, strong) dispatch_queue_t concurentQueue;

@end

@implementation HNReadWriteLock

#pragma mark - Life Cycle

- (instancetype)initWithQueueLabel:(NSString *)queueLabel {
    self = [super init];
    if (self) {
        NSString *concurentQueueLabel = nil;
        if ([HNValidator isValidString:queueLabel]) {
            concurentQueueLabel = queueLabel;
        } else {
            concurentQueueLabel = [NSString stringWithFormat:@"com.hinadata.readWriteLock.%p", self];
        }
        
        self.concurentQueue = dispatch_queue_create([concurentQueueLabel UTF8String], DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

#pragma mark - Public Methods

- (id)readWithBlock:(id(^)(void))block {
    if (!block) {
        return nil;
    }
    
    __block id obj = nil;
    dispatch_sync(self.concurentQueue, ^{
        obj = block();
    });
    return obj;
}

- (void)writeWithBlock:(void (^)(void))block {
    if (!block) {
        return;
    }
    
    dispatch_barrier_async(self.concurentQueue, ^{
        block();
    });
}

@end
