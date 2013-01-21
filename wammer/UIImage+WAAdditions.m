//
//  UIImage+WAAdditions.m
//  wammer
//
//  Created by kchiu on 12/12/20.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "UIImage+WAAdditions.h"

@implementation UIImage (WAAdditions)

- (void)makeThumbnailWithOptions:(WAThumbnailType)type completeBlock:(WAImageProcessComplete)didCompleteBlock {

  __weak UIImage *wSelf = self;
  [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
    UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:wSelf.CGImage type:type orientation:wSelf.imageOrientation];
    didCompleteBlock(scaledImage);
  }];

}

- (void)makeBlurredImageWithCompleteBlock:(WAImageProcessComplete)didCompleteBlock {

  __weak UIImage *wSelf = self;
  [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
    UIImage *blurredImage = [WAImageProcessing blurredImageWithCGImage:wSelf.CGImage orientation:wSelf.imageOrientation];
    didCompleteBlock(blurredImage);
  }];

}

@end
