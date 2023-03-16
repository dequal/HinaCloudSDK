//
// HNNodeObject.m
// HinaDataSDK
//
// Created by hina on 2022/4/6.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNNodeObject.h"
#import "HNJSONUtil.h"

static NSString * const kHNNodeObjectId = @"id";
static NSString * const kHNNodeObjectName = @"name";
static NSString * const kHNNodeObjectInterceptor = @"interceptor";
static NSString * const kHNNodeObjectParam = @"param";

static NSString * const kHNNodeFileName = @"hina_data_node";

@interface HNNodeObject ()

@property (nonatomic, strong) HNInterceptor *interceptor;

@end

@implementation HNNodeObject

- (instancetype)initWithDictionary:(NSDictionary<NSString *,id> *)dictionary {
    NSParameterAssert(dictionary[kHNNodeObjectId]);
    NSParameterAssert(dictionary[kHNNodeObjectName]);
    NSParameterAssert(dictionary[kHNNodeObjectInterceptor]);
    self = [super init];
    if (self) {
        _nodeID = dictionary[kHNNodeObjectId];
        _name = dictionary[kHNNodeObjectName];
        _interceptorClassName = dictionary[kHNNodeObjectInterceptor];
        _param = dictionary[kHNNodeObjectParam];
        
        Class cla = NSClassFromString(self.interceptorClassName);
        if (cla && [cla respondsToSelector:@selector(interceptorWithParam:)]) {
            _interceptor = [cla interceptorWithParam:self.param];
        }
    }
    return self;
}

- (instancetype)initWithNodeID:(NSString *)nodeID name:(NSString *)name interceptor:(HNInterceptor *)interceptor {
    NSParameterAssert(nodeID);
    NSParameterAssert(name);
    NSParameterAssert(interceptor);
    self = [super init];
    if (self) {
        _nodeID = nodeID;
        _name = name;
        _interceptor = interceptor;
    }
    return self;
}

+ (NSDictionary<NSString *, HNNodeObject *> *)loadFromBundle:(NSBundle *)bundle {
    NSURL *url = [bundle URLForResource:kHNNodeFileName withExtension:@"json"];
    if (!url) {
        return nil;
    }
    NSArray *array = [HNJSONUtil JSONObjectWithData:[NSData dataWithContentsOfURL:url]];
    NSMutableDictionary *nodes = [NSMutableDictionary dictionaryWithCapacity:array.count];
    for (NSDictionary *dic in array) {
        HNNodeObject *node = [[HNNodeObject alloc] initWithDictionary:dic];
        nodes[node.nodeID] = node;
    }
    return nodes;
}

@end
