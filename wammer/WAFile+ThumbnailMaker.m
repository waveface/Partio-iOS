//
//  WAFile+ThumbnailMaker.m
//  wammer
//
//  Created by kchiu on 12/9/6.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFile+ThumbnailMaker.h"
#import "WADataStore.h"
#import <UIImage+IRAdditions.h>
#import <QuartzCore+IRAdditions.h>

static CGFloat const kWAFileExtraSmallImageSideLength = 166;
static CGFloat const kWAFileSmallImageSideLength = 512;
static CGFloat const kWAFileMediumImageSideLength = 1024;
static CGFloat const kWAFileLargeImageSideLength = 2048;

@implementation WAFile (ThumbnailMaker)

- (void)makeThumbnailsWithImage:(UIImage *)image options:(WAThumbnailMakeOptions)options {

	NSParameterAssert(image);

	WADataStore *ds = [WADataStore defaultStore];
	CGSize imageSize = image.size;
	UIImage *standardImage = [image irStandardImage];

	if (options & WAThumbnailMakeOptionSmall) {
		CGFloat const smallSideLength = kWAFileSmallImageSideLength;
		
		if ((imageSize.width > smallSideLength) || (imageSize.height > smallSideLength)) {
			
			UIImage *smallThumbnailImage = [standardImage irScaledImageWithSize:IRGravitize((CGRect){ CGPointZero, (CGSize){ smallSideLength, smallSideLength } }, image.size, kCAGravityResizeAspect).size];
			
			self.smallThumbnailFilePath = [[ds persistentFileURLForData:UIImageJPEGRepresentation(smallThumbnailImage, 0.85f) extension:@"jpeg"] path];
			
		} else {
			
			self.smallThumbnailFilePath = [[ds persistentFileURLForData:UIImageJPEGRepresentation(standardImage, 0.85f) extension:@"jpeg"] path];
			
		}
	}
	
	if (options & WAThumbnailMakeOptionMedium) {
		CGFloat const mediumSideLength = kWAFileMediumImageSideLength;
		
		if ((imageSize.width > mediumSideLength) || (imageSize.height > mediumSideLength)) {
			
			UIImage *thumbnailImage = [standardImage irScaledImageWithSize:IRGravitize((CGRect){ CGPointZero, (CGSize){ mediumSideLength, mediumSideLength } }, image.size, kCAGravityResizeAspect).size];
			
			self.thumbnailFilePath = [[ds persistentFileURLForData:UIImageJPEGRepresentation(thumbnailImage, 0.85f) extension:@"jpeg"] path];
			
		} else {
			
			self.thumbnailFilePath = [[ds persistentFileURLForData:UIImageJPEGRepresentation(standardImage, 0.85f) extension:@"jpeg"] path];
			
		}
	}

	if (options & WAThumbnailMakeOptionExtraSmall) {
		CGFloat const extraSmallSideLength = kWAFileExtraSmallImageSideLength;
		
		if ((imageSize.width > extraSmallSideLength) || (imageSize.height > extraSmallSideLength)) {
			
			UIImage *extraSmallThumbnailImage = [standardImage irScaledImageWithSize:IRGravitize((CGRect){ CGPointZero, (CGSize){ extraSmallSideLength, extraSmallSideLength } }, image.size, kCAGravityResizeAspect).size];
			
			self.extraSmallThumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForData:UIImageJPEGRepresentation(extraSmallThumbnailImage, 0.85f) extension:@"jpeg"] path];
			
		} else {
			
			self.extraSmallThumbnailFilePath = [[[WADataStore defaultStore] persistentFileURLForData:UIImageJPEGRepresentation(standardImage, 0.85f) extension:@"jpeg"] path];
			
		}
	}
}

@end
