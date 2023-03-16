//
// HNExposureManager.m
// HinaDataSDK
//
// Created by hina on 2022/8/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNExposureManager.h"
#import "HNConfigOptions+Exposure.h"
#import "HNExposureData+Private.h"
#import "UIView+ExposureIdentifier.h"
#import "HNExposureConfig+Private.h"
#import "HNSwizzle.h"
#import "UIView+ExposureListener.h"
#import "UIScrollView+ExposureListener.h"
#import "UIViewController+ExposureListener.h"
#import "HNMethodHelper.h"
#import "HNLog.h"


static NSString *const kHNExposureViewMark = @"hinadata_exposure_mark";

@implementation HNExposureManager

+ (instancetype)defaultManager {
    static dispatch_once_t onceToken;
    static HNExposureManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[HNExposureManager alloc] init];
        [manager addListener];
        [manager swizzleMethods];
    });
    return manager;
}

- (void)setConfigOptions:(HNConfigOptions *)configOptions {
    _configOptions = configOptions;
    self.enable = YES;
}

- (void)addExposureView:(UIView *)view withData:(HNExposureData *)data {
    if (!view) {
        HNLogError(@"View to expose should not be nil");
        return;
    }
    if (!data.event || ([data.event isKindOfClass:[NSString class]] && data.event.length == 0)) {
        HNLogError(@"Event name should not be empty or nil");
        return;
    }
    if (!data.config) {
        data.config = self.configOptions.exposureConfig;
    }
    __block BOOL exist = NO;
    [self.exposureViewObjects enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(HNExposureViewObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.view) {
            [obj clear];
            [self.exposureViewObjects removeObject:obj];
            return;
        }
        if ((!data.exposureIdentifier && obj.view == view) || (data.exposureIdentifier && [obj.exposureData.exposureIdentifier isEqualToString:data.exposureIdentifier])) {
            obj.exposureData = data;
            obj.view = view;
            exist = YES;
            *stop = YES;
        }
    }];
    if (exist) {
        return;
    }
    HNExposureViewObject *exposureViewObject = [[HNExposureViewObject alloc] initWithView:view exposureData:data];
    exposureViewObject.view.hinadata_exposureMark = kHNExposureViewMark;
    //get view related items, such as viewController, scrollView, state
    if (![view isKindOfClass:[UITableViewCell class]] && ![view isKindOfClass:[UICollectionViewCell class]]) {
        exposureViewObject.scrollView = (UIScrollView *)[self nearbyScrollViewByView:view];
    }
    [exposureViewObject addExposureViewObserver];
    [self.exposureViewObjects addObject:exposureViewObject];
    [exposureViewObject exposureConditionCheck];
}

- (void)removeExposureView:(UIView *)view withExposureIdentifier:(NSString *)identifier {
    if (!view) {
        return;
    }
    [self.exposureViewObjects enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(HNExposureViewObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.view == view) {
            if (!identifier || [obj.exposureData.exposureIdentifier isEqualToString:identifier]) {
                [obj clear];
                [self.exposureViewObjects removeObject:obj];
            }
            *stop = YES;
        }
    }];
}

- (HNExposureViewObject *)exposureViewWithView:(UIView *)view {
    if (!view) {
        return nil;
    }
    for (HNExposureViewObject *exposureViewObject in self.exposureViewObjects) {
        if (exposureViewObject.view != view) {
            continue;
        }
        if (!exposureViewObject.exposureData.exposureIdentifier) {
            return exposureViewObject;
        }
        if (exposureViewObject.exposureData.exposureIdentifier && view.exposureIdentifier && [exposureViewObject.exposureData.exposureIdentifier isEqualToString:view.exposureIdentifier]) {
            return exposureViewObject;
        }
        return nil;
    }
    return nil;
}

- (UIView *)nearbyScrollViewByView:(UIView *)view {
    UIView *superView = view.superview;
    if ([superView isKindOfClass:[UIScrollView class]] || !superView) {
        return superView;
    }
    return [self nearbyScrollViewByView:superView];
}

- (void)addListener {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeVisible:) name:UIWindowDidBecomeVisibleNotification object:nil];
}

- (void)swizzleMethods {
    [HNMethodHelper swizzleRespondsToSelector];
    [UIView sa_swizzleMethod:@selector(didMoveToSuperview) withMethod:@selector(hinadata_didMoveToSuperview) error:NULL];
    BOOL isSuccess = [UITableView sa_swizzleMethod:@selector(setDelegate:) withMethod:@selector(hinadata_exposure_setDelegate:) error:NULL];
    [UICollectionView sa_swizzleMethod:@selector(setDelegate:) withMethod:@selector(hinadata_exposure_setDelegate:) error:NULL];
    [UIViewController sa_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(hinadata_exposure_viewDidAppear:) error:NULL];
    [UIViewController sa_swizzleMethod:@selector(viewDidDisappear:) withMethod:@selector(hinadata_exposure_viewDidDisappear:) error:NULL];
}

- (void)applicationDidEnterBackground {
    for (HNExposureViewObject *exposureViewObject in self.exposureViewObjects) {
        if (exposureViewObject.state == HNExposureViewStateExposing || exposureViewObject.state == HNExposureViewStateVisible) {
            exposureViewObject.state = HNExposureViewStateBackgroundInvisible;
            [exposureViewObject.timer stop];
        }
    }
}

- (void)applicationDidBecomeActive {
    for (HNExposureViewObject *exposureViewObject in self.exposureViewObjects) {
        if (exposureViewObject.state == HNExposureViewStateBackgroundInvisible) {
            exposureViewObject.state = HNExposureViewStateVisible;
            if (!exposureViewObject.exposureData.config.repeated && exposureViewObject.lastExposure > 0) {
                continue;
            }
            // convert to string to compare float number
            NSComparisonResult result = [[NSString stringWithFormat:@"%.2f",exposureViewObject.lastAreaRate] compare:[NSString stringWithFormat:@"%.2f",exposureViewObject.exposureData.config.areaRate]];
            if (result != NSOrderedAscending) {
                [exposureViewObject.timer start];
            }
        }
    }
}

- (void)windowDidBecomeVisible:(NSNotification *)notification {
    UIWindow *visibleWindow = notification.object;
    if (!visibleWindow) {
        return;
    }

    HNExposureViewObject *exposureViewObject = [self exposureViewWithView:visibleWindow];
    if (!exposureViewObject) {
        return;
    }
    [exposureViewObject exposureConditionCheck];
}

-(NSMutableArray<HNExposureViewObject *> *)exposureViewObjects {
    if (!_exposureViewObjects) {
        _exposureViewObjects = [NSMutableArray array];
    }
    return _exposureViewObjects;
}

@end
