//
// HNUIViewInternalProperties.h
// HinaDataSDK
//
// Created by hina on 2022/8/30.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>

@protocol HNUIViewControllerInternalProperties <NSObject>

@property (nonatomic, copy, readonly) NSString *hinadata_screenName;
@property (nonatomic, copy, readonly) NSString *hinadata_title;

@end

@protocol HNUIViewInternalProperties <NSObject>

@property (nonatomic, weak, readonly) UIViewController<HNUIViewControllerInternalProperties> *hinadata_viewController;

@end
