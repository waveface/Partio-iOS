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
	if (!image) {
	  didCompleteBlock(nil);
	  return;
	}
	
	if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
	  UIImage *scaledImage = [WAImageProcessing scaledImageWithUIImage:image type:type];
	  didCompleteBlock(scaledImage);
	} else {
	  UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:image.CGImage type:type orientation:image.imageOrientation];
	  didCompleteBlock(scaledImage);
	}
  }];

}

- (UIImage *)loadDecompressedImage {

  NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:self], @"%s only avaiable for existing file path", __FUNCTION__);

  NSData *imageData = [NSData dataWithContentsOfFile:self options:NSDataReadingMappedIfSafe error:nil];
  CGImageRef decompressedImage = NULL;
  if (imageData) {
    CGDataProviderRef imageDataProvider = CGDataProviderCreateWithCFData((__bridge CFDataRef)imageData);
    CGImageRef image = CGImageCreateWithJPEGDataProvider(imageDataProvider, NULL, NO, kCGRenderingIntentDefault);
    CGContextRef bitmapContext = CGBitmapContextCreate(NULL, CGImageGetWidth(image), CGImageGetHeight(image), CGImageGetBitsPerComponent(image), CGImageGetWidth(image) * 4, CGColorSpaceCreateDeviceRGB(), kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    decompressedImage = CGBitmapContextCreateImage(bitmapContext);
    CGDataProviderRelease(imageDataProvider);
    CGImageRelease(image);
    CGContextRelease(bitmapContext);
  }

  UIImage *returnedImage = [UIImage imageWithCGImage:decompressedImage];

  if (decompressedImage) {
    CGImageRelease(decompressedImage);
  }
  
  return returnedImage;

}

@end
