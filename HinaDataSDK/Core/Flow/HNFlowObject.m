//
// HNFlowObject.m
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNFlowObject.h"
#import "HNJSONUtil.h"

static NSString * const kHNFlowObjectId = @"id";
static NSString * const kHNFlowObjectName = @"name";
static NSString * const kHNFlowObjectTasks = @"tasks";
static NSString * const kHNFlowObjectParam = @"param";

static NSString * const kHNFlowFileName = @"hina_data_flow.json";

@implementation HNFlowObject

- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dictionary {
    NSParameterAssert(dictionary[kHNFlowObjectId]);
    NSParameterAssert(dictionary[kHNFlowObjectName]);
    self = [super init];
    if (self) {
        _flowID = dictionary[kHNFlowObjectId];
        _name = dictionary[kHNFlowObjectName];
        _param = dictionary[kHNFlowObjectParam];

        NSArray *array = dictionary[kHNFlowObjectTasks];
        if ([array.firstObject isKindOfClass:[NSDictionary class]]) {
            NSMutableArray *tasks = [NSMutableArray array];
            for (NSDictionary *dic in array) {
                [tasks addObject:[[HNTaskObject alloc] initWithDictionary:dic]];
            }
            _tasks = tasks;
        } else {
            _taskIDs = array;
        }
    }
    return self;
}

- (instancetype)initWithFlowID:(NSString *)flowID name:(NSString *)name tasks:(NSArray<HNTaskObject *> *)tasks {
    self = [super init];
    if (self) {
        _flowID = flowID;
        _name = name;
        _tasks = tasks;
    }
    return self;
}

- (HNTaskObject *)taskForID:(NSString *)taskID {
    if (![taskID isKindOfClass:NSString.class]) {
        return nil;
    }
    for (HNTaskObject *task in self.tasks) {
        if ([task.taskID isEqualToString:taskID]) {
            return task;
        }
    }
    return nil;
}

+ (NSDictionary<NSString *, HNFlowObject *> *)loadFromBundle:(NSBundle *)bundle {
    NSString *jsonPath = [bundle pathForResource:kHNFlowFileName ofType:nil];
    if (!jsonPath) {
        return nil;
    }
    NSArray *array = [HNJSONUtil JSONObjectWithData:[NSData dataWithContentsOfFile:jsonPath]];
    NSMutableDictionary *flows = [NSMutableDictionary dictionaryWithCapacity:array.count];
    for (NSDictionary *dic in array) {
        HNFlowObject *object = [[HNFlowObject alloc] initWithDictionary:dic];
        flows[object.flowID] = object;
    }
    return flows;
}

@end
