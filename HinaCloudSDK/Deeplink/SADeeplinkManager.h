//
// SADeepLinkManager.h
// HinaCloudSDK
//
// Created by 彭远洋 on 2020/1/6.
// Copyright © 2015-2022 Sensors Data Co., Ltd. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import "HNBuildOptions.h"
#import "SAModuleProtocol.h"
#import "SADeepLinkProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNBuildOptions (DeepLinkPrivate)

@property (nonatomic, assign) BOOL enableDeepLink;

@end

@interface SADeepLinkManager : NSObject <SAModuleProtocol, SAOpenURLProtocol, SADeepLinkModuleProtocol>

+ (instancetype)defaultManager;

@property (nonatomic, assign, getter=isEnable) BOOL enable;
@property (nonatomic, strong) HNBuildOptions *configOptions;

@property (nonatomic, copy) SADeepLinkCompletion oldCompletion;
@property (nonatomic, copy) SADeepLinkCompletion completion;

- (void)trackDeepLinkLaunchWithURL:(NSString *)url;

- (void)requestDeferredDeepLink:(NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
