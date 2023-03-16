//
// HNViewElementInfoFactory.h
// HinaDataSDK
//
// Created by hina on 2022/2/18.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import "HNViewElementInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNViewElementInfoFactory : NSObject

+ (HNViewElementInfo *)elementInfoWithView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
