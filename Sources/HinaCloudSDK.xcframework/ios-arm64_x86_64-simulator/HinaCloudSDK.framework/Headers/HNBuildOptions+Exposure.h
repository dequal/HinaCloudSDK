

#import <Foundation/Foundation.h>
#import "HNBuildOptions.h"
#import "HNExposureConfig.h"
#import "HNExposureData.h"
#import "HinaCloudSDK+Exposure.h"
#import "UIView+ExposureIdentifier.h"

NS_ASSUME_NONNULL_BEGIN

@interface HNBuildOptions (Exposure)

/// global exposure config settings, default value with areaRate = 0, stayDuration = 0, repeated = YES
@property (nonatomic, copy) HNExposureConfig *exposureConfig;

@end

NS_ASSUME_NONNULL_END
