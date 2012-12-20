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

  [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
    UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:self.CGImage type:type orientation:self.imageOrientation];
    didCompleteBlock(scaledImage);
  }];

}

@end
