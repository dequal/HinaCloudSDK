//
// HNTaskObject.m
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNTaskObject.h"
#import "HNJSONUtil.h"
#import "HNValidator.h"

static NSString * const kHNTaskObjectId = @"id";
static NSString * const kHNTaskObjectName = @"name";
static NSString * const kHNTaskObjectParam = @"param";
static NSString * const kHNTaskObjectNodes = @"nodes";

static NSString * const kHNTaskFileName = @"hina_data_task";

@implementation HNTaskObject

- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dictionary {
    NSParameterAssert(dictionary[kHNTaskObjectId]);
    NSParameterAssert(dictionary[kHNTaskObjectName]);
    self = [super init];
    if (self) {
        _taskID = dictionary[kHNTaskObjectId];
        _name = dictionary[kHNTaskObjectName];
        _param = dictionary[kHNTaskObjectParam];

        NSArray *array = dictionary[kHNTaskObjectNodes];
        if ([array.firstObject isKindOfClass:[NSDictionary class]]) {
            NSMutableArray *nodes = [NSMutableArray array];
            for (NSDictionary *dic in array) {
                [nodes addObject:[[HNNodeObject alloc] initWithDictionary:dic]];
            }
            _nodes = nodes;
        } else {
            _nodeIDs = array;
        }
    }
    return self;
}

- (instancetype)initWithTaskID:(NSString *)taskID name:(NSString *)name nodes:(NSArray<HNNodeObject *> *)nodes {
    self = [super init];
    if (self) {
        _taskID = taskID;
        _name = name;
        _nodes = [nodes mutableCopy];
    }
    return self;
}

- (void)insertNode:(HNNodeObject *)node atIndex:(NSUInteger)index {
    if (index > self.nodes.count) {
        return;
    }
    [self.nodes insertObject:node atIndex:index];
}

- (NSInteger)indexOfNodeWithID:(NSString *)nodeID {
    __block NSInteger index = -1;
    if (![HNValidator isValidString:nodeID]) {
        return index;
    }
    [self.nodes enumerateObjectsUsingBlock:^(HNNodeObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.nodeID isEqualToString:nodeID]) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}
+ (NSDictionary<NSString *, HNTaskObject *> *)loadFromBundle:(NSBundle *)bundle {
    NSURL *url = [bundle URLForResource:kHNTaskFileName withExtension:@"json"];
    if (!url) {
        return nil;
    }
    NSArray *array = [HNJSONUtil JSONObjectWithData:[NSData dataWithContentsOfURL:url]];
    NSMutableDictionary *tasks = [NSMutableDictionary dictionaryWithCapacity:array.count];
    for (NSDictionary *dic in array) {
        HNTaskObject *object = [[HNTaskObject alloc] initWithDictionary:dic];
        tasks[object.taskID] = object;
    }
    return tasks;
}

@end
