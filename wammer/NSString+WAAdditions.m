//
//  NSString+WAAdditions.m
//  wammer
//
//  Created by kchiu on 12/12/20.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "NSString+WAAdditions.h"

@implementation NSString (WAAdditions)

- (void)makeThumbnailWithOptions:(WAThumbnailType)type completeBlock:(WAImageProcessComplete)didCompleteBlock {

  NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:self], @"%s only avaiable for existing file path", __FUNCTION__);

  __weak NSString *wSelf = self;
  [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:wSelf options:NSDataReadingMappedIfSafe error:nil]];
    UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:image.CGImage type:type orientation:image.imageOrientation];
    didCompleteBlock(scaledImage);
  }];

}

@end
