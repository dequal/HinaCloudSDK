

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HNUIViewAutoTrackDelegate <NSObject>

//UITableView
@optional
- (NSDictionary *)hinaCloud_tableView:(UITableView *)tableView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;

//UICollectionView
@optional
- (NSDictionary *)hinaCloud_collectionView:(UICollectionView *)collectionView autoTrackPropertiesAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface UIView (HinaCloud)

/// viewID
@property (nonatomic, copy) NSString *hinaCloudViewID;

/// AutoTrack 时，是否忽略该 View
@property (nonatomic, assign) BOOL hinaDataIgnoreView;

/// AutoTrack 发生在 SendAction 之前还是之后，默认是 SendAction 之前
@property (nonatomic, assign) BOOL hinaCloudAutoTrackAfterSendAction;

/// AutoTrack 时，View 的扩展属性
@property (nonatomic, strong) NSDictionary *hinaCloudViewProperties;

@property (nonatomic, weak, nullable) id<HNUIViewAutoTrackDelegate> hinaCloudDelegate;

@end

@interface UIImage (HinaCloud)

@property (nonatomic, copy) NSString* hinaCloudImageName;

@end

NS_ASSUME_NONNULL_END
