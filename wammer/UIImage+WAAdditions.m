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
	
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
	  UIImage *scaledImage = [WAImageProcessing scaledImageWithUIImage:self type:type];
	  didCompleteBlock(scaledImage);
	} else {
	  UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:self.CGImage type:type orientation:self.imageOrientation];
	  didCompleteBlock(scaledImage);
	}
	
  }];

}

@end
