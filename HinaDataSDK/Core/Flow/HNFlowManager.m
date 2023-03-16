//
// HNFlowManager.m
// HinaDataSDK
//
// Created by hina on 2022/2/17.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNFlowManager.h"
#import "HNInterceptor.h"
#import "HNJSONUtil.h"
#import "HNLog.h"

//static NSString * const kHNNodeFileName = @"hina_data_node";
//static NSString * const kHNTaskFileName = @"hina_data_task";
//static NSString * const kHNFlowFileName = @"hina_data_flow";
//NSString * const kHNTrackFlowId = @"hinadata_track_flow";
//NSString * const kHNFlushFlowId = @"hinadata_flush_flow";
// 😄😄😄😄  hina_data_
static NSString * const kHNNodeFileName = @"hina_data_node";
static NSString * const kHNTaskFileName = @"hina_data_task";
static NSString * const kHNFlowFileName = @"hina_data__flow";
NSString * const kHNTrackFlowId = @"hinadata_track_flow";
NSString * const kHNFlushFlowId = @"hinadata_flush_flow";

@interface HNFlowManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, HNNodeObject *> *nodes;
@property (nonatomic, strong) NSMutableDictionary<NSString *, HNTaskObject *> *tasks;
@property (nonatomic, strong) NSMutableDictionary<NSString *, HNFlowObject *> *flows;

@end

@implementation HNFlowManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static HNFlowManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNFlowManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _nodes = [NSMutableDictionary dictionary];
        _tasks = [NSMutableDictionary dictionary];
        _flows = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - load

- (void)loadFlows {
    NSBundle *saBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[HNFlowManager class]] pathForResource:@"HinaDataSDK" ofType:@"bundle"]];
    [self.nodes addEntriesFromDictionary:[HNNodeObject loadFromBundle:saBundle]];
    [self.tasks addEntriesFromDictionary:[HNTaskObject loadFromBundle:saBundle]];
    [self.flows addEntriesFromDictionary:[HNFlowObject loadFromBundle:saBundle]];
}

#pragma mark - add

- (void)registerFlow:(HNFlowObject *)flow {
    NSParameterAssert(flow.flowID);
    if (!flow.flowID) {
        return;
    }
    self.flows[flow.flowID] = flow;
}

- (void)registerFlows:(NSArray<HNFlowObject *> *)flows {
    for (HNFlowObject *flow in flows) {
        [self registerFlow:flow];
    }
}

- (HNFlowObject *)flowForID:(NSString *)flowID {
    return self.flows[flowID];
}

#pragma mark - start

- (void)startWithFlowID:(NSString *)flowID input:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    NSParameterAssert(self.flows[flowID]);
    input.configOptions = self.configOptions;
    HNFlowObject *object = self.flows[flowID];
    if (!object) {
        return completion(input);
    }
    [self startWithFlow:object input:input completion:completion];
}

- (void)startWithFlow:(HNFlowObject *)flow input:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    input.configOptions = self.configOptions;
    [input.param addEntriesFromDictionary:flow.param];
    [self processWithFlow:flow taskIndex:0 input:input completion:^(HNFlowData * _Nonnull output) {
        if (completion) {
            completion(output);
        }
    }];
}

- (void)processWithFlow:(HNFlowObject *)flow taskIndex:(NSInteger)index input:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    HNTaskObject *task = nil;
    if (index < flow.tasks.count) {
        task = flow.tasks[index];
    } else if (index < flow.taskIDs.count) {
        task = self.tasks[flow.taskIDs[index]];
    } else {
        return completion(input);
    }
    [input.param addEntriesFromDictionary:task.param];

    [self processWithTask:task nodeIndex:0 input:input completion:^(HNFlowData *output) {
        if (output.state == HNFlowStateStop) {
            return completion(output);
        }

        // 执行下一个 task
        [self processWithFlow:flow taskIndex:index + 1 input:output completion:completion];
    }];
}

- (void)processWithTask:(HNTaskObject *)task nodeIndex:(NSInteger)index input:(HNFlowData *)input completion:(HNFlowDataCompletion)completion {
    HNNodeObject *node = nil;
    if (index < task.nodes.count) {
        node = task.nodes[index];
    } else if (index < task.nodeIDs.count) {
        node = self.nodes[task.nodeIDs[index]];
    } else {
        return completion(input);
    }

    // 部分模块内的拦截器可能加载失败，此时节点不可用，则直接跳过
    if (!node.interceptor) {
        return [self processWithTask:task nodeIndex:index + 1 input:input completion:completion];
    }

    [node.interceptor processWithInput:input completion:^(HNFlowData *output) {
        if (output.message) {
            HNLogError(@"The node(id: %@, name: %@, interceptor: %@) error: %@", node.nodeID, node.name, [node.interceptor class], output.message);
            output.message = nil;
        }
        if (output.state == HNFlowStateError) {
            HNLogWarn(@"The node(id: %@, name: %@, interceptor: %@) stop the task(id: %@, name: %@).", node.nodeID, node.name, [node.interceptor class], task.taskID, task.name);
        }
        if (output.state == HNFlowStateStop || output.state == HNFlowStateError) {
            return completion(output);
        }

        // 执行下一个 node
        [self processWithTask:task nodeIndex:index + 1 input:output completion:completion];
    }];
}

@end
