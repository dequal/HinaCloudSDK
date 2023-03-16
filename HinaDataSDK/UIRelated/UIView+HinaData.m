//
// UIView+HinaData.m
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIView+HinaData.h"
#import "HNWeakPropertyContainer.h"
#include <objc/runtime.h>

static void *const kHNHinaDataViewIDKey = (void *)&kHNHinaDataViewIDKey;
static void *const kHNHinaDataIgnoreViewKey = (void *)&kHNHinaDataIgnoreViewKey;
static void *const kHNHinaDataAutoTrackAfterSendActionKey = (void *)&kHNHinaDataAutoTrackAfterSendActionKey;
static void *const kHNHinaDataViewPropertiesKey = (void *)&kHNHinaDataViewPropertiesKey;
static void *const kHNHinaDataImageNameKey = (void *)&kHNHinaDataImageNameKey;

@implementation UIView (HinaData)

//viewID
- (NSString *)hinaDataViewID {
    return objc_getAssociatedObject(self, kHNHinaDataViewIDKey);
}

- (void)setHinaDataViewID:(NSString *)hinaDataViewID {
    objc_setAssociatedObject(self, kHNHinaDataViewIDKey, hinaDataViewID, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

//ignoreView
- (BOOL)hinaDataIgnoreView {
    return [objc_getAssociatedObject(self, kHNHinaDataIgnoreViewKey) boolValue];
}

- (void)setHinaDataIgnoreView:(BOOL)hinaDataIgnoreView {
    objc_setAssociatedObject(self, kHNHinaDataIgnoreViewKey, [NSNumber numberWithBool:hinaDataIgnoreView], OBJC_ASSOCIATION_ASSIGN);
}

//afterSendAction
- (BOOL)hinaDataAutoTrackAfterSendAction {
    return [objc_getAssociatedObject(self, kHNHinaDataAutoTrackAfterSendActionKey) boolValue];
}

- (void)setHinaDataAutoTrackAfterSendAction:(BOOL)hinaDataAutoTrackAfterSendAction {
    objc_setAssociatedObject(self, kHNHinaDataAutoTrackAfterSendActionKey, [NSNumber numberWithBool:hinaDataAutoTrackAfterSendAction], OBJC_ASSOCIATION_ASSIGN);
}

//viewProperty
- (NSDictionary *)hinaDataViewProperties {
    return objc_getAssociatedObject(self, kHNHinaDataViewPropertiesKey);
}

- (void)setHinaDataViewProperties:(NSDictionary *)hinaDataViewProperties {
    objc_setAssociatedObject(self, kHNHinaDataViewPropertiesKey, hinaDataViewProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<HNUIViewAutoTrackDelegate>)hinaDataDelegate {
    HNWeakPropertyContainer *container = objc_getAssociatedObject(self, @"hinaDataDelegate");
    return container.weakProperty;
}

- (void)setHinaDataDelegate:(id<HNUIViewAutoTrackDelegate>)hinaDataDelegate {
    HNWeakPropertyContainer *container = [HNWeakPropertyContainer containerWithWeakProperty:hinaDataDelegate];
    objc_setAssociatedObject(self, @"hinaDataDelegate", container, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIImage (HinaData)

- (NSString *)hinaDataImageName {
    return objc_getAssociatedObject(self, kHNHinaDataImageNameKey);
}

- (void)setHinaDataImageName:(NSString *)hinaDataImageName {
    objc_setAssociatedObject(self, kHNHinaDataImageNameKey, hinaDataImageName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
