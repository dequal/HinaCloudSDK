//
// HNVisualizedAutoTrackConnection.h
// HinaDataSDK
//
// Created by hina on 2022/9/4.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.


#import <Foundation/Foundation.h>



@protocol HNVisualizedMessage;

@interface HNVisualizedConnection : NSObject

@property (nonatomic, readonly) BOOL connected;

- (void)sendMessage:(id<HNVisualizedMessage>)message;
- (void)startConnectionWithFeatureCode:(NSString *)featureCode url:(NSString *)urlStr;
- (void)close;

// 是否正在进行可视化全埋点上传页面信息
- (BOOL)isVisualizedConnecting;
@end
