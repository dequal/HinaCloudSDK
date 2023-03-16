//
// UIScrollView+HNDelegateHashTable.m
// HinaDataSDK
//
// Created by hina on 2022/9/3.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#import "UIScrollView+HNDelegateHashTable.h"
#import <objc/runtime.h>

static const void *kHNTableViewDelegateHashTable = &kHNTableViewDelegateHashTable;
static const void *kHNCollectionViewDelegateHashTable = &kHNCollectionViewDelegateHashTable;

static const void *kHNTableViewExposureDelegateHashTable = &kHNTableViewExposureDelegateHashTable;
static const void *kHNCollectionViewExposureDelegateHashTable = &kHNCollectionViewExposureDelegateHashTable;

@implementation UITableView (HNDelegateHashTable)

- (void)setHinadata_delegateHashTable:(NSHashTable *)delegateHashTable {
    objc_setAssociatedObject(self, kHNTableViewDelegateHashTable, delegateHashTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSHashTable *)hinadata_delegateHashTable {
    NSHashTable *delegateHashTable = objc_getAssociatedObject(self, kHNTableViewDelegateHashTable);
    if (!delegateHashTable) {
        delegateHashTable = [NSHashTable weakObjectsHashTable];
        self.hinadata_delegateHashTable = delegateHashTable;
    }
    return delegateHashTable;
}

- (void)setHinadata_exposure_delegateHashTable:(NSHashTable *)hinadata_exposure_delegateHashTable {
    objc_setAssociatedObject(self, kHNTableViewExposureDelegateHashTable, hinadata_exposure_delegateHashTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSHashTable *)hinadata_exposure_delegateHashTable {
    NSHashTable *exposureDelegateHashTable = objc_getAssociatedObject(self, kHNTableViewExposureDelegateHashTable);
    if (!exposureDelegateHashTable) {
        exposureDelegateHashTable = [NSHashTable weakObjectsHashTable];
        self.hinadata_exposure_delegateHashTable = exposureDelegateHashTable;
    }
    return exposureDelegateHashTable;
}

@end

@implementation UICollectionView (HNDelegateHashTable)

- (void)setHinadata_delegateHashTable:(NSHashTable *)delegateHashTable {
    objc_setAssociatedObject(self, kHNCollectionViewDelegateHashTable, delegateHashTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSHashTable *)hinadata_delegateHashTable {
    NSHashTable *delegateHashTable = objc_getAssociatedObject(self, kHNCollectionViewDelegateHashTable);
    if (!delegateHashTable) {
        delegateHashTable = [NSHashTable weakObjectsHashTable];
        self.hinadata_delegateHashTable = delegateHashTable;
    }
    return delegateHashTable;
}

- (void)setHinadata_exposure_delegateHashTable:(NSHashTable *)hinadata_exposure_delegateHashTable {
    objc_setAssociatedObject(self, kHNCollectionViewExposureDelegateHashTable, hinadata_exposure_delegateHashTable, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSHashTable *)hinadata_exposure_delegateHashTable {
    NSHashTable *exposureDelegateHashTable = objc_getAssociatedObject(self, kHNCollectionViewExposureDelegateHashTable);
    if (!exposureDelegateHashTable) {
        exposureDelegateHashTable = [NSHashTable weakObjectsHashTable];
        self.hinadata_exposure_delegateHashTable = exposureDelegateHashTable;
    }
    return exposureDelegateHashTable;
}

@end
