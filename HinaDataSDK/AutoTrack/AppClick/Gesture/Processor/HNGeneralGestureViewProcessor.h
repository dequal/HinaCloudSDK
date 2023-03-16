//
// HNGeneralGestureViewProcessor.h
// HinaDataSDK
//
// Created by hina on 2022/2/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface HNGeneralGestureViewProcessor : NSObject

/// 校验手势是否能够采集事件
@property (nonatomic, assign, readonly) BOOL isTrackable;

/// 手势事件采集时的控件元素
@property (nonatomic, strong, readonly) UIView *trackableView;

/// 初始化传入的手势
@property (nonatomic, strong, readonly) UIGestureRecognizer *gesture;

- (instancetype)initWithGesture:(UIGestureRecognizer *)gesture;

@end

@interface HNLegacyAlertGestureViewProcessor : HNGeneralGestureViewProcessor
@end

@interface HNNewAlertGestureViewProcessor : HNGeneralGestureViewProcessor
@end

@interface HNLegacyMenuGestureViewProcessor : HNGeneralGestureViewProcessor
@end

@interface HNMenuGestureViewProcessor : HNGeneralGestureViewProcessor
@end

@interface HNTableCellGestureViewProcessor : HNGeneralGestureViewProcessor
@end

@interface HNCollectionCellGestureViewProcessor : HNGeneralGestureViewProcessor
@end

NS_ASSUME_NONNULL_END
