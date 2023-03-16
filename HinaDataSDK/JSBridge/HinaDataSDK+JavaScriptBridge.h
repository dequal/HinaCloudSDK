//
// HinaDataSDK+JavaScriptBridge.h
// HinaDataSDK
//
// Created by hina on 2022/9/13.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HinaDataSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface HinaDataSDK (JavaScriptBridge)

- (void)trackFromH5WithEvent:(NSString *)eventInfo;

- (void)trackFromH5WithEvent:(NSString *)eventInfo enableVerify:(BOOL)enableVerify;

@end

@interface HNConfigOptions (JavaScriptBridge)

/// 是否开启 WKWebView 的 H5 打通功能，该功能默认是关闭的
@property (nonatomic) BOOL enableJavaScriptBridge;

@end

NS_ASSUME_NONNULL_END
