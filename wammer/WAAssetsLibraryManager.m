//
//  WAAssetsLibraryManager.m
//  wammer
//
//  Created by kchiu on 12/9/3.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAAssetsLibraryManager.h"

@implementation WAAssetsLibraryManager

+ (WAAssetsLibraryManager *) defaultManager {
	
	static WAAssetsLibraryManager *returnedManager = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		
		returnedManager = [[self alloc] init];
    
	});
	
	return returnedManager;

}

- (id)init {

	self = [super init];

	if (self) {

		self.assetsLibrary = [[ALAssetsLibrary alloc] init];

	}

	return self;

}

- (void)assetForURL:(NSURL *)assetURL resultBlock:(ALAssetsLibraryAssetForURLResultBlock)resultBlock failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock {

	[self.assetsLibrary assetForURL:assetURL resultBlock:resultBlock failureBlock:failureBlock];

}

- (void)writeImageToSavedPhotosAlbum:(CGImageRef)imageRef orientation:(ALAssetOrientation)orientation completionBlock:(ALAssetsLibraryWriteImageCompletionBlock)completionBlock {

	[self.assetsLibrary writeImageToSavedPhotosAlbum:imageRef orientation:orientation completionBlock:completionBlock];

}

@end
