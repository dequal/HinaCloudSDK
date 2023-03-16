//
// UIView+HinaData.h
// HinaDataSDK
//
// Created by hina on 2022/8/29.
// Copyright © 2018-2024 Hina Data Co., Ltd. All rights reserved.
//
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HNUIViewAutoTrackDelegate <NSObject>

//UITableView
@optional
- (NSDictionary *)hinaData_tableView:(UITableView *)tableView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;

//UICollectionView
@optional
- (NSDictionary *)hinaData_collectionView:(UICollectionView *)collectionView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface UIView (HinaData)

/// viewID
@property (nonatomic, copy) NSString *hinaDataViewID;

/// AutoTrack 时，是否忽略该 View
@property (nonatomic, assign) BOOL hinaDataIgnoreView;

/// AutoTrack 发生在 SendAction 之前还是之后，默认是 SendAction 之前
@property (nonatomic, assign) BOOL hinaDataAutoTrackAfterSendAction;

/// AutoTrack 时，View 的扩展属性
@property (nonatomic, strong) NSDictionary *hinaDataViewProperties;

@property (nonatomic, weak, nullable) id<HNUIViewAutoTrackDelegate> hinaDataDelegate;

@end

@interface UIImage (HinaData)

@property (nonatomic, copy) NSString* hinaDataImageName;

@end

NS_ASSUME_NONNULL_END
