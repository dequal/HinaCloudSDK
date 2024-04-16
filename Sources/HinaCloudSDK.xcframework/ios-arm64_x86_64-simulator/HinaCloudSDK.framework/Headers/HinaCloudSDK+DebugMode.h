

#import "HinaCloudSDK.h"

NS_ASSUME_NONNULL_BEGIN

@interface HinaCloudSDK (DebugMode)

/**
 * @abstract
 * 设置是否显示 debugInfoView
 *
 * @discussion
 * 设置是否显示 debugInfoView，默认显示
 *
 * @param show             是否显示
 */
- (void)showDebugInfoView:(BOOL)show API_UNAVAILABLE(macos);

- (HinaCloudDebugMode)debugMode;

@end

NS_ASSUME_NONNULL_END
