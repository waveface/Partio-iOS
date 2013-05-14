//
//  ALAsset+WAAdditions.h
//  wammer
//
//  Created by kchiu on 12/12/20.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>
#import "WAImageProcessing.h"

@interface ALAsset (WAAdditions)

- (void)makeThumbnailWithOptions:(WAThumbnailType)type completeBlock:(WAImageProcessComplete)didCompleteBlock;
- (UIImage *) cachedPresentableImage;

@property (nonatomic, readonly) CLLocation *gpsLocation;

@end
