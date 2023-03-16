//
// HNExposureView.m
// HinaDataSDK
//
// Created by hina on 2022/8/10.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "HNExposureViewObject.h"
#import "HinaDataSDK.h"
#import "HNModuleManager.h"
#import "HNExposureData+Private.h"
#import "HNExposureConfig+Private.h"
#import "HNValidator.h"
#import "HNUIProperties.h"
#import "HNConstants+Private.h"
#import "UIView+ExposureListener.h"
#import "HNLog.h"
#import "UIView+HNInternalProperties.h"

static void * const kHNExposureViewFrameContext = (void*)&kHNExposureViewFrameContext;
static void * const kHNExposureViewAlphaContext = (void*)&kHNExposureViewAlphaContext;
static void * const kHNExposureViewHiddenContext = (void*)&kHNExposureViewHiddenContext;
static void * const kHNExposureViewContentOffsetContext = (void*)&kHNExposureViewContentOffsetContext;

@implementation HNExposureViewObject

- (instancetype)initWithView:(UIView *)view exposureData:(HNExposureData *)exposureData {
    self = [super init];
    if (self) {
        _view = view;
        _exposureData = exposureData;
        _state = HNExposureViewStateInvisible;
        _type = HNExposureViewTypeNormal;
        _lastExposure = 0;
        __weak typeof(self) weakSelf = self;
        _timer = [[HNExposureTimer alloc] initWithDuration:exposureData.config.stayDuration completeBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf triggerExposure];
            });
        }];
    }
    return self;
}

- (void)addExposureViewObserver {
    [self.view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:kHNExposureViewFrameContext];
    [self.view addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:kHNExposureViewAlphaContext];
    [self.view addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:kHNExposureViewHiddenContext];
    self.view.hinadata_exposure_observer = self;
}

- (void)removeExposureObserver {
    [self removeExposureViewObserver];
    [self removeExposureScrollViewObserver];
}

- (void)removeExposureViewObserver {
    if (!self.view.observationInfo || self.view.hinadata_exposure_observer != self) {
        return;
    }
    @try {
        [self.view removeObserver:self forKeyPath:@"frame" context:kHNExposureViewFrameContext];
        [self.view removeObserver:self forKeyPath:@"alpha" context:kHNExposureViewAlphaContext];
        [self.view removeObserver:self forKeyPath:@"hidden" context:kHNExposureViewHiddenContext];
    } @catch (NSException *exception) {
        HNLogError(@"%@", exception);
    } @finally {
        self.view.hinadata_exposure_observer = nil;
    }
}

- (void)removeExposureScrollViewObserver {
    if (!self.scrollView.observationInfo || self.scrollView.hinadata_exposure_observer != self) {
        return;
    }
    @try {
        [self.scrollView removeObserver:self forKeyPath:@"contentOffset" context:kHNExposureViewContentOffsetContext];
    } @catch (NSException *exception) {
        HNLogError(@"%@", exception);
    } @finally {
        self.scrollView.hinadata_exposure_observer = nil;
    }
}

- (void)clear {
    [self.timer invalidate];
    [self removeExposureObserver];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kHNExposureViewFrameContext) {
        [self observeFrameChange:change];
    } else if (context == kHNExposureViewAlphaContext) {
        [self observeAlphaChange:change];
    } else if (context == kHNExposureViewHiddenContext) {
        [self observeHiddenChange:change];
    } else if (context == kHNExposureViewContentOffsetContext) {
        [self observeContentOffsetChange:change];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)observeFrameChange:(NSDictionary *)change {
    NSValue *newValue = change[NSKeyValueChangeNewKey];
    NSValue *oldValue = change[NSKeyValueChangeOldKey];
    if (![newValue isKindOfClass:[NSValue class]] || ![oldValue isKindOfClass:[NSValue class]]) {
        return;
    }
    if ([newValue isEqualToValue:oldValue]) {
        return;
    }
    if ([self.view isKindOfClass:[UITableViewCell class]] || [self.view isKindOfClass:[UICollectionViewCell class]]) {
        if (self.state == HNExposureViewStateInvisible || self.state == HNExposureViewStateExposing) {
            return;
        }
    }
    [self exposureConditionCheck];
}

- (void)observeAlphaChange:(NSDictionary *)change {
    NSNumber *newValue = change[NSKeyValueChangeNewKey];
    NSNumber *oldValue = change[NSKeyValueChangeOldKey];
    if (![newValue isKindOfClass:[NSNumber class]] || ![oldValue isKindOfClass:[NSNumber class]]) {
        return;
    }
    if ([newValue isEqualToNumber:oldValue]) {
        return;
    }
    float oldAlphaValue = oldValue.floatValue;
    float newAlphaValue = newValue.floatValue;
    if (oldAlphaValue > 0.01 && newAlphaValue <= 0.01) {
        self.state = HNExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (oldAlphaValue <= 0.01 && newAlphaValue > 0.01) {
        if (self.lastAreaRate >= self.exposureData.config.areaRate) {
            [self.timer start];
            self.state = HNExposureViewStateVisible;
            return;
        }
        [self exposureConditionCheck];
        return;
    }
}

- (void)observeHiddenChange:(NSDictionary *)change {
    NSNumber *newValue = change[NSKeyValueChangeNewKey];
    NSNumber *oldValue = change[NSKeyValueChangeOldKey];
    if (![newValue isKindOfClass:[NSNumber class]] || ![oldValue isKindOfClass:[NSNumber class]]) {
        return;
    }
    if ([newValue isEqualToNumber:oldValue]) {
        return;
    }
    BOOL newHiddenValue = [newValue boolValue];
    BOOL oldHiddenValue = [oldValue boolValue];
    if (oldHiddenValue && !newHiddenValue) {
        if (self.lastAreaRate >= self.exposureData.config.areaRate) {
            [self.timer start];
            self.state = HNExposureViewStateVisible;
            return;
        }
        [self exposureConditionCheck];
        return;
    }
    if (!oldHiddenValue && newHiddenValue) {
        self.state = HNExposureViewStateInvisible;
        [self.timer stop];
    }
}

- (void)observeContentOffsetChange:(NSDictionary *)change {
    NSValue *newValue = change[NSKeyValueChangeNewKey];
    NSValue *oldValue = change[NSKeyValueChangeOldKey];
    if (![newValue isKindOfClass:[NSValue class]] || ![oldValue isKindOfClass:[NSValue class]]) {
        return;
    }
    if ([newValue isEqualToValue:oldValue]) {
        return;
    }
    if ([self.view isKindOfClass:[UITableViewCell class]] || [self.view isKindOfClass:[UICollectionViewCell class]]) {
        if (self.state == HNExposureViewStateInvisible || self.state == HNExposureViewStateExposing) {
            return;
        }
    }
    [self exposureConditionCheck];
}

- (void)exposureConditionCheck {
    if (!self.view) {
        return;
    }

    if (!self.exposureData.config.repeated && self.lastExposure > 0) {
        return;
    }

    if ([self.view isKindOfClass:[UIWindow class]] && self.view != [self topWindow]) {
        self.state = HNExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (!self.view.window) {
        self.state = HNExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (self.view.isHidden) {
        self.state = HNExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (self.view.alpha <= 0.01) {
        self.state = HNExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (CGRectEqualToRect(self.view.frame, CGRectZero)) {
        self.state = HNExposureViewStateInvisible;
        [self.timer stop];
        return;
    }

    CGRect visibleRect = CGRectZero;
    if ([self.view isKindOfClass:[UIWindow class]]) {
        visibleRect = CGRectIntersection(self.view.frame, [UIScreen mainScreen].bounds);
    } else {
        CGRect viewToWindowRect = [self.view convertRect:self.view.bounds toView:self.view.window];
        CGRect windowRect = self.view.window.bounds;
        CGRect viewVisableRect = CGRectIntersection(viewToWindowRect, windowRect);
        visibleRect = viewVisableRect;
        if (self.scrollView) {
            CGRect scrollViewToWindowRect = [self.scrollView convertRect:self.scrollView.bounds toView:self.scrollView.window];
            CGRect scrollViewVisableRect = CGRectIntersection(scrollViewToWindowRect, windowRect);
            visibleRect = CGRectIntersection(viewVisableRect, scrollViewVisableRect);
        }
    }

    if (CGRectIsNull(visibleRect)) {
        self.state = HNExposureViewStateInvisible;
        [self.timer stop];
        self.lastAreaRate = 0;
        return;
    }
    CGFloat visableRate = (visibleRect.size.width * visibleRect.size.height) / (self.view.bounds.size.width * self.view.bounds.size.height);
    self.lastAreaRate = visableRate;
    if (visableRate <= 0) {
        self.state = HNExposureViewStateInvisible;
        [self.timer stop];
        return;
    }
    if (self.state == HNExposureViewStateExposing) {
        return;
    }
    // convert to string to compare float number
    NSComparisonResult result = [[NSString stringWithFormat:@"%.2f",visableRate] compare:[NSString stringWithFormat:@"%.2f",self.exposureData.config.areaRate]];

    if (result != NSOrderedAscending) {
        [self.timer start];
    } else {
        [self.timer stop];
    }
}

- (UIWindow *)topWindow {
    NSArray<UIWindow *> *windows;
    if (@available(iOS 13.0, *)) {
        __block UIWindowScene *scene = nil;
        [[UIApplication sharedApplication].connectedScenes.allObjects enumerateObjectsUsingBlock:^(UIScene * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[UIWindowScene class]]) {
                scene = (UIWindowScene *)obj;
                *stop = YES;
            }
        }];
        windows = scene.windows;
    } else {
        windows = UIApplication.sharedApplication.windows;
    }

    if (!windows || windows.count < 1) {
        return nil;
    }

    NSArray *sortedWindows = [windows sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        UIWindow *window1 = obj1;
        UIWindow *window2 = obj2;
        if (window1.windowLevel < window2.windowLevel) {
            return NSOrderedAscending;
        } else if (window1.windowLevel == window2.windowLevel) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }];
    return sortedWindows.lastObject;
}

- (void)triggerExposure {
    self.state = HNExposureViewStateExposing;
    self.lastExposure = [[NSDate date] timeIntervalSince1970];
    [self.timer stop];
    //track event
    if (self.view == nil) {
        return;
    }
    if ([self.view isKindOfClass:[UITableViewCell class]] || [self.view isKindOfClass:[UICollectionViewCell class]]) {
        [self trackEventWithScrollView:self.scrollView cell:self.view atIndexPath:self.indexPath];
    } else {
        [self trackEventWithView:self.view properties:nil];
    }
}

- (void)trackEventWithView:(UIView *)view properties:(NSDictionary<NSString *,id> *)properties {
    if (view == nil) {
        return;
    }
    NSMutableDictionary *eventProperties = [[NSMutableDictionary alloc]init];
    [eventProperties addEntriesFromDictionary:[HNUIProperties propertiesWithView:view viewController:self.viewController]];
    if ([HNValidator isValidDictionary:properties]) {
        [eventProperties addEntriesFromDictionary:properties];
    }
    [eventProperties addEntriesFromDictionary:self.exposureData.properties];
    NSString *elementPath = [HNUIProperties elementPathForView:view atViewController:self.viewController];
    eventProperties[kHNEventPropertyElementPath] = elementPath;
    [[HinaDataSDK sharedInstance] track:self.exposureData.event withProperties:eventProperties];
}

- (void)trackEventWithScrollView:(UIScrollView *)scrollView cell:(UIView *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSMutableDictionary *properties = [NSMutableDictionary dictionaryWithDictionary:[HNUIProperties propertiesWithScrollView:scrollView cell:cell]];
    if (!properties) {
        return;
    }
    NSDictionary *dic = [HNUIProperties propertiesWithAutoTrackDelegate:scrollView andIndexPath:indexPath];
    [properties addEntriesFromDictionary:dic];
    [self trackEventWithView:cell properties:properties];
}

- (void)setScrollView:(UIScrollView *)scrollView {
    if (_scrollView == scrollView) {
        return;
    }
    @try {
        [self removeExposureScrollViewObserver];
        if (scrollView.hinadata_exposure_observer == self && scrollView.observationInfo) {
            [scrollView removeObserver:self forKeyPath:@"contentOffset" context:kHNExposureViewContentOffsetContext];
        }
        [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:kHNExposureViewContentOffsetContext];
        scrollView.hinadata_exposure_observer = self;
    } @catch (NSException *exception) {
        HNLogError(@"%@", exception);
    } @finally {
        _scrollView = scrollView;
    }
}

- (void)setView:(UIView *)view {
    if (_view == view) {
        return;
    }
    [self removeExposureViewObserver];
    _view = view;
    [self addExposureViewObserver];
}

- (UIViewController *)viewController {
    if (self.scrollView) {
        return self.scrollView.hinadata_viewController;
    }
    return self.view.hinadata_viewController;
}

-(void)dealloc {
    [self removeExposureObserver];
}

@end
