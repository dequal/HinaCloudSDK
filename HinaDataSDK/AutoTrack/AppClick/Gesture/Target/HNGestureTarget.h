//
// HNGestureTarget.h
// HinaDataSDK
//
// Created by hina on 2022/2/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNGestureTarget : NSObject

+ (HNGestureTarget * _Nullable)targetWithGesture:(UIGestureRecognizer *)gesture;

- (void)trackGestureRecognizerAppClick:(UIGestureRecognizer *)gesture;

@end

NS_ASSUME_NONNULL_END
