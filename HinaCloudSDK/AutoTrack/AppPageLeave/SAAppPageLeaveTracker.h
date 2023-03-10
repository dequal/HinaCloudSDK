//
// SAAppPageLeaveTracker.h
// HinaCloudSDK
//
// Created by 陈玉国 on 2021/7/19.
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


#import "SAAppTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface SAPageLeaveObject : NSObject

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, copy) NSString *referrerURL;

@end

@interface SAAppPageLeaveTracker : SAAppTracker

@property (nonatomic, strong) NSMutableDictionary<NSString *, SAPageLeaveObject *> *pageLeaveObjects;

- (void)trackEvents;
- (void)trackPageEnter:(UIViewController *)viewController;
- (void)trackPageLeave:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
