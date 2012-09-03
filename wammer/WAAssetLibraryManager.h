//
//  WAAssetLibraryManager.h
//  wammer
//
//  Created by kchiu on 12/9/3.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface WAAssetLibraryManager : NSObject

+ (WAAssetLibraryManager *) defaultManager;
- (void)assetForURL:(NSURL *)assetURL resultBlock:(ALAssetsLibraryAssetForURLResultBlock)resultBlock failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock;

@end
