//
// HNGestureViewProcessorFactory.h
// HinaDataSDK
//
// Created by hina on 2022/2/19.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import "HNGeneralGestureViewProcessor.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNGestureViewProcessorFactory : NSObject

+ (HNGeneralGestureViewProcessor *)processorWithGesture:(UIGestureRecognizer *)gesture;

@end


NS_ASSUME_NONNULL_END
