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
    UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:[representation fullResolutionImage] type:type orientation:irUIImageOrientationFromAssetOrientation([representation orientation])];
    didCompleteBlock(scaledImage);
  }];

}

@end
