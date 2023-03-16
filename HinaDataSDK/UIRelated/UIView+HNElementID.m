//
// UIView+HNElementID.m
// HinaDataSDK
//
// Created by hina on 2022/8/30.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HNElementID.h"
#import "UIView+HinaData.h"

@implementation UIView (HNElementID)

- (NSString *)hinadata_elementId {
    return self.hinaDataViewID;
}

@end
