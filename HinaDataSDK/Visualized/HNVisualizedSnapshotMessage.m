//
// HNVisualizedSnapshotMessage.m
// HinaDataSDK
//
// Created by hina on 2022/9/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif


#import <CommonCrypto/CommonDigest.h>
#import "HNVisualizedSnapshotMessage.h"
#import "HNApplicationStateSerializer.h"
#import "HNObjectIdentityProvider.h"
#import "HNObjectSerializerConfig.h"
#import "HNVisualizedConnection.h"
#import "HNConstants+Private.h"
#import "HNVisualizedManager.h"
#import "HNVisualizedObjectSerializerManager.h"
#import "HNCommonUtility.h"

#pragma mark -- Snapshot Request

NSString * const HNVisualizedSnapshotRequestMessageType = @"snapshot_request";

static NSString * const kSnapshotSerializerConfigKey = @"snapshot_class_descriptions";

@implementation HNVisualizedSnapshotRequestMessage

+ (instancetype)message {
    return [(HNVisualizedSnapshotRequestMessage *)[self alloc] initWithType:HNVisualizedSnapshotRequestMessageType];
}

- (HNObjectSerializerConfig *)configuration {
    NSDictionary *config = [self payloadObjectForKey:@"config"];
    return config ? [[HNObjectSerializerConfig alloc] initWithDictionary:config] : nil;
}


// 构建页面信息，包括截图和元素数据
- (NSOperation *)responseCommandWithConnection:(HNVisualizedConnection *)connection {
    HNObjectSerializerConfig *serializerConfig = self.configuration;

    __weak HNVisualizedConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        __strong HNVisualizedConnection *conn = weak_connection;

        // Get the object identity provider from the connection's session store or create one if there is none already.
        HNObjectIdentityProvider *objectIdentityProvider = [[HNObjectIdentityProvider alloc] init];

        HNApplicationStateSerializer *serializer = [[HNApplicationStateSerializer alloc] initWithConfiguration:serializerConfig objectIdentityProvider:objectIdentityProvider];

        HNVisualizedSnapshotResponseMessage *snapshotMessage = [HNVisualizedSnapshotResponseMessage message];

        dispatch_async(dispatch_get_main_queue(), ^{
            [serializer screenshotImageForAllWindowWithCompletionHandler:^(UIImage *image) {
                // 添加待校验事件
                snapshotMessage.debugEvents = HNVisualizedManager.defaultManager.eventCheck.eventCheckResult;
                // 清除事件缓存
                [HNVisualizedManager.defaultManager.eventCheck cleanEventCheckResult];

                // 添加诊断信息
                snapshotMessage.logInfos = HNVisualizedManager.defaultManager.visualPropertiesTracker.logInfos;

                // 最后构建截图，并设置 imageHash
                snapshotMessage.screenshot = image;

                // payloadHash 不变即截图相同，页面不变，则不再解析页面元素信息
                if ([[HNVisualizedObjectSerializerManager sharedInstance].lastPayloadHash isEqualToString:snapshotMessage.payloadHash]) {
                    [conn sendMessage:[HNVisualizedSnapshotResponseMessage message]];

                    // 不包含页面元素等数据，只发送页面基本信息，重置 payloadHash 为截图 hash
//                    [[HNVisualizedObjectSerializerManager sharedInstance] resetLastPayloadHash:snapshotMessage.originImageHash];
                } else {
                    // 清空页面配置信息
                    [[HNVisualizedObjectSerializerManager sharedInstance] resetObjectSerializer];

                    // 解析页面信息
                    NSDictionary *serializedObjects = [serializer objectHierarchyForRootObject];
                    snapshotMessage.serializedObjects = serializedObjects;
                    [conn sendMessage:snapshotMessage];

                    // 更新 payload hash 信息
                    [[HNVisualizedObjectSerializerManager sharedInstance] updateLastPayloadHash:snapshotMessage.payloadHash];
                }
            }];
        });
    }];

    return operation;
}

@end

#pragma mark -- Snapshot Response
@interface HNVisualizedSnapshotResponseMessage()
@property (nonatomic, copy, readwrite) NSString *originImageHash;
@end

@implementation HNVisualizedSnapshotResponseMessage

+ (instancetype)message {
    return [(HNVisualizedSnapshotResponseMessage *)[self alloc] initWithType:@"snapshot_response"];
}

- (void)setScreenshot:(UIImage *)screenshot {
    id payloadObject = nil;
    NSString *imageHash = nil;
    if (screenshot) {
        NSData *jpegSnapshotImageData = UIImageJPEGRepresentation(screenshot, 0.5);
        if (jpegSnapshotImageData) {
            payloadObject = [jpegSnapshotImageData base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
            imageHash = [HNCommonUtility hashStringWithData:jpegSnapshotImageData];

            // 保留原始图片 hash 值
            self.originImageHash = imageHash;
        }
    }

    // 如果包含其他数据，拼接到 imageHash，防止前端数据未刷新
    NSString *payloadHash = [[HNVisualizedObjectSerializerManager sharedInstance] fetchPayloadHashWithImageHash:imageHash];

    self.payloadHash = payloadHash;
    [self setPayloadObject:payloadObject forKey:@"screenshot"];
    [self setPayloadObject:payloadHash forKey:@"image_hash"];
}

- (void)setDebugEvents:(NSArray<NSDictionary *> *)debugEvents {
    if (debugEvents.count == 0) {
        return;
    }
    
    // 更新 imageHash
    [[HNVisualizedObjectSerializerManager sharedInstance] refreshPayloadHashWithData:debugEvents];
    
    [self setPayloadObject:debugEvents forKey:@"event_debug"];
}

- (void)setLogInfos:(NSArray<NSDictionary *> *)logInfos {
    if (logInfos.count == 0) {
        return;
    }
    // 更新 imageHash
    [[HNVisualizedObjectSerializerManager sharedInstance] refreshPayloadHashWithData:logInfos];

    [self setPayloadObject:logInfos forKey:@"log_info"];
}

- (UIImage *)screenshot {
    NSString *base64Image = [self payloadObjectForKey:@"screenshot"];
    NSData *imageData =[[base64Image dataUsingEncoding:NSUTF8StringEncoding] base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    return imageData ? [UIImage imageWithData:imageData] : nil;
}

- (void)setSerializedObjects:(NSDictionary *)serializedObjects {
    [self setPayloadObject:serializedObjects forKey:@"serialized_objects"];
}

- (NSDictionary *)serializedObjects {
    return [self payloadObjectForKey:@"serialized_objects"];
}

@end



