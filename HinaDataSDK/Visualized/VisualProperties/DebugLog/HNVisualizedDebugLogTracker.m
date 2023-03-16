//
// HNVisualizedDebugLogTracker.m
// HinaDataSDK
//
// Created by hina on 2022/3/3.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNVisualizedDebugLogTracker.h"
#import "HNVisualizedLogger.h"
#import "HNVisualizedUtils.h"
#import "HNViewNode.h"
#import "HNLog+Private.h"
#import "UIView+HNVisualProperties.h"
#import "HNConstants+Private.h"

@interface HNVisualizedDebugLogTracker()<HNVisualizedLoggerDelegate>
@property (atomic, strong, readwrite) NSMutableArray<NSMutableDictionary *> *debugLogInfos;
@property (nonatomic, strong) HNVisualizedLogger *logger;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
/// node 节点的行号
@property (nonatomic, assign) NSInteger nodeRowIndex;

@end

@implementation HNVisualizedDebugLogTracker

- (instancetype)init {
    self = [super init];
    if (self) {
        NSString *serialQueueLabel = [NSString stringWithFormat:@"com.hinadata.HNVisualizedDebugLogTracker.%p", self];
        _serialQueue = dispatch_queue_create([serialQueueLabel UTF8String], DISPATCH_QUEUE_SERIAL);
        [self addDebugLogger];
        _debugLogInfos = [NSMutableArray array];

    }
    return self;
}

- (void)addDebugLogger {
    // 添加 log 实现
    HNVisualizedLogger *visualizedLogger = [[HNVisualizedLogger alloc] init];
    [HNLog addLogger:visualizedLogger];

    visualizedLogger.delegate = self;
    self.logger = visualizedLogger;
}

#pragma mark HNVisualizedLoggerDelegate
- (void)loggerMessage:(NSDictionary *)messageDic {
    if (!messageDic) {
        return;
    }
    NSMutableDictionary *eventLogInfo = [self.debugLogInfos lastObject];
    NSMutableArray *messages = eventLogInfo[@"messages"];
    [messages addObject:messageDic];
}

#pragma mark - addDebugLog
- (void)addTrackEventWithView:(UIView *)view withConfig:(NSDictionary *)config {
    HNViewNode *viewNode = view.hinadata_viewNode;
    if (!viewNode) {
        return;
    }
    NSMutableDictionary *appClickEventInfo = [NSMutableDictionary dictionary];
    appClickEventInfo[@"event_type"] = @"appclick";
    appClickEventInfo[@"element_path"] = viewNode.elementPath;
    appClickEventInfo[@"element_position"] = viewNode.elementPosition;
    appClickEventInfo[@"element_content"] = viewNode.elementContent;
    appClickEventInfo[@"screen_name"] = viewNode.screenName;

    [self addTrackEventInfo:appClickEventInfo withConfig:config];
}

- (void)addTrackEventInfo:(NSDictionary *)eventInfo withConfig:(NSDictionary *)config {
    NSMutableDictionary *eventLogInfo = [NSMutableDictionary dictionary];
    [self.debugLogInfos addObject:eventLogInfo];

    // 1. 添加事件信息
    [eventLogInfo addEntriesFromDictionary:eventInfo];

    // 2. 解析配置信息
    eventLogInfo[@"config"] = config;

    // 3. 构建日志信息
    NSMutableArray *messages = [NSMutableArray array];
    eventLogInfo[@"messages"] = messages;

    // 4. 添加 node 信息
    [self addAllNodeInfo];
}

#pragma mark addNodeInfo
// 实现 node 递归遍历，打印节点树
- (void)addAllNodeInfo {
    // 主线程获取 keyWindow
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [HNVisualizedUtils currentValidKeyWindow];
        HNViewNode *rootNode = keyWindow.hinadata_viewNode.nextNode;

        // 异步递归遍历
        dispatch_async(self.serialQueue, ^{
            self.nodeRowIndex = 0;
            @try {
                NSString *nodeMessage = [self showViewHierarchy:rootNode level:0];
                NSMutableDictionary *eventLogInfo = [self.debugLogInfos lastObject];
                eventLogInfo[@"objects"] = nodeMessage;
            } @catch (NSException *exception) {
                NSString *logMessage = [HNVisualizedLogger buildLoggerMessageWithTitle:@"diagnostic information" message:@"log node tree error: %@", exception];
                HNLogWarn(@"%@", logMessage);
            }
        });
    });
}

// 显示每层 node 的信息
- (NSString *)showViewHierarchy:(HNViewNode *)node level:(NSInteger)level {
    NSMutableString *description = [NSMutableString string];

    NSMutableString *indent = [NSMutableString stringWithFormat:@"%ld",(long)self.nodeRowIndex];
    // 不同位数字后空格数不同，保证对齐
    NSInteger log =  self.nodeRowIndex > 0 ? log10(self.nodeRowIndex) : 0;
    NSInteger spaceCount = log > 3 ? 0 : 3 - log;
    for (NSInteger index = 0 ; index < spaceCount; index ++) {
        [indent appendString:@" "];
    }
    for (NSInteger i = 0; i < level; i++) {
        [indent appendString:@" |"];
    }

    self.nodeRowIndex ++;
    [description appendFormat:@"\n%@%@", indent, node];

    /* 此处执行 copy
     1. 遍历同时，可能存在主线程异步的 node 构建，从而修改 subNodes，防止遍历同时修改的崩溃
     2. 尽可能获取事件发生时刻的 node，而不是最新的
     */
    for (HNViewNode *node1 in [node.subNodes copy]) {
        [description appendFormat:@"%@", [self showViewHierarchy:node1 level:level + 1]];
    }
    return [description copy];
}

- (void)dealloc {
    // 移除注入的 logger
    [HNLog removeLogger:self.logger];
}

@end
