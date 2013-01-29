//
//  ALAsset+WAAdditions.m
//  wammer
//
//  Created by kchiu on 12/12/20.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "ALAsset+WAAdditions.h"
#import "AssetsLibrary+IRAdditions.h"

@implementation ALAsset (WAAdditions)

- (void)makeThumbnailWithOptions:(WAThumbnailType)type completeBlock:(WAImageProcessComplete)didCompleteBlock {

  ALAssetRepresentation *representation = [self defaultRepresentation];

  [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
	
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
	  UIImage *scaledImage = [WAImageProcessing scaledImageWithUIImage:[UIImage imageWithCGImage:[representation fullResolutionImage]
																						   scale:1.0f
																					 orientation:irUIImageOrientationFromAssetOrientation([representation orientation])]
																  type:type];
	  didCompleteBlock(scaledImage);
	} else {
	  UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:[representation fullResolutionImage]
																  type:type
														   orientation:irUIImageOrientationFromAssetOrientation([representation orientation])];
	  didCompleteBlock(scaledImage);
	}
  }];

}

@end
