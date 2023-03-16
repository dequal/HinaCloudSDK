//
// HNUIViewPathProperties.h
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HNUIViewPathProperties <NSObject>

@optional
@property (nonatomic, copy, readonly) NSString *hinadata_itemPath;
@property (nonatomic, copy, readonly) NSString *hinadata_similarPath;
@property (nonatomic, copy, readonly) NSIndexPath *hinadata_IndexPath;
@property (nonatomic, copy, readonly) NSString *hinadata_elementPath;

@end

NS_ASSUME_NONNULL_END
