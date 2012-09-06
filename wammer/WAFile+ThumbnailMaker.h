//
//  WAFile+ThumbnailMaker.h
//  wammer
//
//  Created by kchiu on 12/9/6.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFile.h"

extern CGFloat const kWAFileExtraSmallImageSideLength;
extern CGFloat const kWAFileSmallImageSideLength;
extern CGFloat const kWAFileMediumImageSideLength;
extern CGFloat const kWAFileLargeImageSideLength;

enum {
	WAThumbnailMakeOptionExtraSmall = 1,
	WAThumbnailMakeOptionSmall = 1 << 1,
	WAThumbnailMakeOptionMedium = 1 << 2,
	WAThumbnailMakeOptionLarge = 1 << 3
}; typedef NSInteger WAThumbnailMakeOptions;

@interface WAFile (ThumbnailMaker)

/** Generate thumbnails with the given image and options.
 *
 *	@param image An image.
 *	@param options The options specify what kind of thumbnails to be generated.
 */
- (void) makeThumbnailsWithImage:(UIImage *)image options:(WAThumbnailMakeOptions)options;


@end
