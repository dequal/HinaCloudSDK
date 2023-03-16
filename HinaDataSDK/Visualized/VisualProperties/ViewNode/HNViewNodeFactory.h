//
// HNViewNodeFactory.h
// HinaDataSDK
//
// Created by hina on 2022/1/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HNViewNode.h"

NS_ASSUME_NONNULL_BEGIN

/// 构造工厂
@interface HNViewNodeFactory : NSObject

+ (nullable HNViewNode *)viewNodeWithView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
