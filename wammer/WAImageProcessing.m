//
//  WAImageProcessing.m
//  wammer
//
//  Created by kchiu on 12/12/18.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAImageProcessing.h"
#import <CoreImage/CoreImage.h>
#import "AssetsLibrary+IRAdditions.h"

static CGFloat const kWAFileExtraSmallImageSideLength = 150; // the side length of asset's square thumbnails in retina display
static CGFloat const kWAFileSmallImageSideLength = 512;
static CGFloat const kWAFileMediumImageSideLength = 1024;
static CGFloat const kWAFileLargeImageSideLength = 2048;

@implementation WAImageProcessing

+ (void)makeThumbnailWithImageFilePath:(NSString *)filePath options:(WAThumbnailMakeOptions)options completeBlock:(WAImageProcessComplete)didCompleteBlock {
  
  if (options & WAThumbnailMakeOptionExtraSmall) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil]];
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:image.CGImage sideLength:kWAFileExtraSmallImageSideLength orientation:image.imageOrientation];
      didCompleteBlock(scaledImage);
    }];
  }
  
  if (options & WAThumbnailMakeOptionSmall) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil]];
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:image.CGImage sideLength:kWAFileSmallImageSideLength orientation:image.imageOrientation];
      didCompleteBlock(scaledImage);
    }];
  }
  
  if (options & WAThumbnailMakeOptionMedium) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil]];
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:image.CGImage sideLength:kWAFileMediumImageSideLength orientation:image.imageOrientation];
      didCompleteBlock(scaledImage);
    }];
  }
  
  if (options & WAThumbnailMakeOptionLarge) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfFile:filePath options:NSDataReadingMappedIfSafe error:nil]];
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:image.CGImage sideLength:kWAFileLargeImageSideLength orientation:image.imageOrientation];
      didCompleteBlock(scaledImage);
    }];
  }
  
}

+ (void)makeThumbnailWithUIImage:(UIImage *)image options:(WAThumbnailMakeOptions)options completeBlock:(WAImageProcessComplete)didCompleteBlock {
  
  if (options & WAThumbnailMakeOptionExtraSmall) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:image.CGImage sideLength:kWAFileExtraSmallImageSideLength orientation:image.imageOrientation];
      didCompleteBlock(scaledImage);
    }];
  }
  
  if (options & WAThumbnailMakeOptionSmall) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:image.CGImage sideLength:kWAFileSmallImageSideLength orientation:image.imageOrientation];
      didCompleteBlock(scaledImage);
    }];
  }
  
  if (options & WAThumbnailMakeOptionMedium) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:image.CGImage sideLength:kWAFileMediumImageSideLength orientation:image.imageOrientation];
      didCompleteBlock(scaledImage);
    }];
  }
  
  if (options & WAThumbnailMakeOptionLarge) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:image.CGImage sideLength:kWAFileLargeImageSideLength orientation:image.imageOrientation];
      didCompleteBlock(scaledImage);
    }];
  }
  
}

+ (void)makeThumbnailWithAsset:(ALAsset *)asset options:(WAThumbnailMakeOptions)options completeBlock:(WAImageProcessComplete)didCompleteBlock {
  
  ALAssetRepresentation *representation = [asset defaultRepresentation];
  
  if (options & WAThumbnailMakeOptionExtraSmall) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:[representation fullResolutionImage] sideLength:kWAFileExtraSmallImageSideLength orientation:irUIImageOrientationFromAssetOrientation([representation orientation])];
      didCompleteBlock(scaledImage);
    }];
  }
  
  if (options & WAThumbnailMakeOptionSmall) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:[representation fullResolutionImage] sideLength:kWAFileSmallImageSideLength orientation:irUIImageOrientationFromAssetOrientation([representation orientation])];
      didCompleteBlock(scaledImage);
    }];
  }
  
  if (options & WAThumbnailMakeOptionMedium) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:[representation fullResolutionImage] sideLength:kWAFileMediumImageSideLength orientation:irUIImageOrientationFromAssetOrientation([representation orientation])];
      didCompleteBlock(scaledImage);
    }];
  }
  
  if (options & WAThumbnailMakeOptionLarge) {
    [[WAImageProcessing sharedImageProcessQueue] addOperationWithBlock:^{
      UIImage *scaledImage = [WAImageProcessing scaledImageWithCGImage:[representation fullResolutionImage] sideLength:kWAFileLargeImageSideLength orientation:irUIImageOrientationFromAssetOrientation([representation orientation])];
      didCompleteBlock(scaledImage);
    }];
  }
  
}

+ (UIImage *)scaledImageWithCGImage:(CGImageRef)image sideLength:(CGFloat)sideLength orientation:(UIImageOrientation)orientation {
  
  CGFloat imageWidth = CGImageGetWidth(image);
  CGFloat imageHeight = CGImageGetHeight(image);
  
  if (imageWidth <= sideLength && imageHeight <= sideLength) {
    return [UIImage imageWithCGImage:image];
  }
  
  CIImage *outputImage = nil;
  CIContext *context = [WAImageProcessing sharedCIContext];
  CGSize maxSize = [context inputImageMaximumSize];
  
  if (imageWidth > maxSize.width || imageHeight > maxSize.height) {
    // scale down by core graphics
    CGFloat xscale = sideLength / imageWidth;
    CGFloat yscale = sideLength / imageHeight;
    CGFloat scale = xscale < yscale ? xscale : yscale;
    CGRect drawnRect = CGRectMake(0, 0, imageWidth*scale, imageHeight*scale);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef cgContext = CGBitmapContextCreate(NULL, drawnRect.size.width, drawnRect.size.height, 8, 0, colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextSetInterpolationQuality(cgContext, kCGInterpolationHigh);
    CGContextClearRect(cgContext, drawnRect);
    CGContextDrawImage(cgContext, drawnRect, image);
    CGImageRef scaledCGImage = CGBitmapContextCreateImage(cgContext);
    outputImage = [CIImage imageWithCGImage:scaledCGImage];
    CGImageRelease(scaledCGImage);
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(cgContext);
  } else {
    // scale down by core image
    CIImage *inputImage = [CIImage imageWithCGImage:image];
    CIFilter *filter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
    [filter setValue:inputImage forKey:@"inputImage"];
    CGFloat scale = (imageWidth > imageHeight) ? sideLength/imageWidth : sideLength/imageHeight;
    [filter setValue:@(scale) forKey:@"inputScale"];
    outputImage = [filter outputImage];
  }
  
  // rotate
  CGAffineTransform transform;
  CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform"];
  [filter setValue:outputImage forKey:@"inputImage"];
  switch (orientation) {
    case UIImageOrientationDown:
    case UIImageOrientationDownMirrored:
      transform = CGAffineTransformMakeRotation(M_PI);
      [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
      outputImage = [filter outputImage];
      break;
      
    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
      transform = CGAffineTransformMakeRotation(M_PI_2);
      [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
      outputImage = [filter outputImage];
      break;
      
    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
      transform = CGAffineTransformMakeRotation(-M_PI_2);
      [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
      outputImage = [filter outputImage];
      break;
      
    default:
      break;
  }
  
  // horizontal flip
  filter = [CIFilter filterWithName:@"CIAffineTransform"];
  [filter setValue:outputImage forKey:@"inputImage"];
  switch (orientation) {
    case UIImageOrientationUpMirrored:
    case UIImageOrientationDownMirrored:
    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRightMirrored:
      transform = CGAffineTransformMakeScale(-1, 1);
      [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
      outputImage = [filter outputImage];
      break;
      
    default:
      break;
  }
  
  // adjust origin
  filter = [CIFilter filterWithName:@"CIAffineTransform"];
  [filter setValue:outputImage forKey:@"inputImage"];
  CGRect extent = [outputImage extent];
  transform = CGAffineTransformMakeTranslation(-extent.origin.x, -extent.origin.y);
  [filter setValue:[NSValue valueWithBytes:&transform objCType:@encode(CGAffineTransform)] forKey:@"inputTransform"];
  outputImage = [filter outputImage];
  
  // draw image
  CGImageRef outputCGImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
  
  UIImage *returnedImage = [UIImage imageWithCGImage:outputCGImage scale:1.0 orientation:UIImageOrientationUp];
  
  CGImageRelease(outputCGImage);
  
  return returnedImage;
  
}

+ (CIContext *)sharedCIContext {
  
  static CIContext *context;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    context = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer:@NO}];
  });
  
  return context;
  
}

+ (NSOperationQueue *)sharedImageProcessQueue {
  
  static NSOperationQueue *queue;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:1];
  });
  
  return queue;
  
}

@end

