//
//  WAAssetsLibraryManager.h
//  wammer
//
//  Created by kchiu on 12/9/3.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface WAAssetsLibraryManager : NSObject

@property (nonatomic, readwrite, strong) ALAssetsLibrary *assetsLibrary;

+ (WAAssetsLibraryManager *) defaultManager;

/** A wrapper for [ALAssetsLibrary assetForURL:resultBlock:failureBlock:] for hook.
 */
- (void)assetForURL:(NSURL *)assetURL resultBlock:(ALAssetsLibraryAssetForURLResultBlock)resultBlock failureBlock:(ALAssetsLibraryAccessFailureBlock)failureBlock;

/** A wrapper for [ALAssetsLibrary writeImageToSavedPhotosAlbum:orientation:completionBlock:] for hook.
 */
- (void)writeImageToSavedPhotosAlbum:(CGImageRef)imageRef orientation:(ALAssetOrientation)orientation completionBlock:(ALAssetsLibraryWriteImageCompletionBlock)completionBlock;

@end
