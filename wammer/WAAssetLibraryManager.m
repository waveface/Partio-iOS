//
//  WAAssetLibraryManager.m
//  wammer
//
//  Created by kchiu on 12/9/3.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAAssetLibraryManager.h"

@interface WAAssetLibraryManager ()

@property (nonatomic, readwrite, strong) ALAssetsLibrary *assetLibrary;

@end

@implementation WAAssetLibraryManager

+ (WAAssetLibraryManager *) defaultManager {
	
	static WAAssetLibraryManager *returnedManager = nil;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		
		returnedManager = [[self alloc] init];
    
	});
	
	return returnedManager;

}

- (id)init {

	self = [super init];

	if (self) {

		self.assetLibrary = [[ALAssetsLibrary alloc] init];

	}

	return self;

}

- (void)assetForURL:(NSURL *)assetURL resultBlock:(ALAssetsLibraryAssetForURLResultBlock)resultBlock failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock {

	[self.assetLibrary assetForURL:assetURL resultBlock:resultBlock failureBlock:failureBlock];

}

@end
