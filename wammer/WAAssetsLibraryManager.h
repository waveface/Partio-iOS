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

/** Invokes a given block passing as a parameter for assets within each day.
 *
 *	@param sinceDate The date to begin enumeration.
 *	@param onProgressBlock The block to invoke for assets within each day. Return YES if the enumeration should be canceled.
 *	@param onCompleteBlock The block to invoke when enumeration finishes.
 *	@param onFailureBlock The block to invoke when unable to enumerate assets.
 */
- (void)enumerateSavedPhotosSince:(NSDate *)sinceDate onProgess:(void (^)(NSArray *assets, NSDate *progressDate, BOOL *stop))onProgressBlock onComplete:(void(^)())onCompleteBlock onFailure:(void(^)(NSError *error))onFailureBlock;

- (void)retrieveTimeSortedPhotosWhenComplete:(void (^)(NSArray *result))onCompleteBlock onFailure:(void (^)(NSError *))onFailureBlock;
@end
