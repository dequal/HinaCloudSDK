//
// HNUIViewElementProperties.h
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HNUIViewElementProperties <NSObject>

@optional
@property (nonatomic, copy, readonly) NSString *hinadata_elementType;
@property (nonatomic, copy, readonly) NSString *hinadata_elementContent;
@property (nonatomic, copy, readonly) NSString *hinadata_elementId;
@property (nonatomic, copy, readonly) NSString *hinadata_elementPosition;

@end

NS_ASSUME_NONNULL_END
