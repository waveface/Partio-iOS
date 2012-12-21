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

  NSString *filePath = [self copy];

  NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:filePath], @"%s only avaiable for existing file path", __FUNCTION__);

  [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil]];
    UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:image.CGImage type:type orientation:image.imageOrientation];
    didCompleteBlock(scaledImage);
  }];

}

@end
