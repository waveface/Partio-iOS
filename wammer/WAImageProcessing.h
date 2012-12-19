//
//  WAImageProcessing.h
//  wammer
//
//  Created by kchiu on 12/12/18.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

enum {
	WAThumbnailMakeOptionExtraSmall = 1,
	WAThumbnailMakeOptionSmall = 1 << 1,
	WAThumbnailMakeOptionMedium = 1 << 2,
	WAThumbnailMakeOptionLarge = 1 << 3
}; typedef NSInteger WAThumbnailMakeOptions;

typedef void(^WAImageProcessComplete)(UIImage *image);

@interface WAImageProcessing : NSObject

+ (void)makeThumbnailWithImageFilePath:(NSString *)filePath options:(WAThumbnailMakeOptions)options completeBlock:(WAImageProcessComplete)didCompleteBlock;
+ (void)makeThumbnailWithUIImage:(UIImage *)image options:(WAThumbnailMakeOptions)options completeBlock:(WAImageProcessComplete)didCompleteBlock;
+ (void)makeThumbnailWithAsset:(ALAsset *)asset options:(WAThumbnailMakeOptions)options completeBlock:(WAImageProcessComplete)didCompleteBlock;

@end
