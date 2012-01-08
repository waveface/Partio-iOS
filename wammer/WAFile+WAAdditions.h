//
//  WAFile+WAAdditions.h
//  wammer
//
//  Created by Evadne Wu on 1/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFile.h"

@interface WAFile (WAAdditions)

@property (nonatomic, readwrite, retain) UIImage *resourceImage;
@property (nonatomic, readwrite, retain) UIImage *thumbnailImage;

- (UIImage *) presentableImage;	//	Conforms to KVO; automatically chooses the highest resolution thing, calls -updatePresentableImage if currently nil
- (UIImage *) updatePresentableImage;	//	Will update `presentableImage` and emit KVO notifications if appropriate 

+ (dispatch_queue_t) sharedResourceHandlingQueue;

- (void) scheduleResourceRetrievalIfPermitted;
- (void) scheduleThumbnailRetrievalIfPermitted;
- (BOOL) canScheduleBlobRetrieval;
- (BOOL) canScheduleExpensiveBlobRetrieval;

- (BOOL) takeResourceFromTemporaryFile:(NSString *)aPath matchingURL:(NSURL *)anURL;
- (BOOL) takeThumbnailFromTemporaryFile:(NSString *)aPath matchingURL:(NSURL *)anURL;
- (BOOL) takeBlobFromTemporaryFile:(NSString *)aPath forKeyPath:(NSString *)fileKeyPath matchingURL:(NSURL *)anURL forKeyPath:(NSString *)urlKeyPath;

@property (nonatomic, readwrite, assign) BOOL validatesResourceImage;
@property (nonatomic, readwrite, assign) BOOL validatesThumbnailImage;

- (BOOL) validateResourceImageIfNeeded:(NSError **)outError;
- (BOOL) validateResourceImageIfNeeded;
- (BOOL) validateResourceImage:(NSError **)outError;
- (BOOL) validateResourceImage;

- (BOOL) validateThumbnailImageIfNeeded:(NSError **)outError;
- (BOOL) validateThumbnailImageIfNeeded;
- (BOOL) validateThumbnailImage:(NSError **)outError;
- (BOOL) validateThumbnailImage;

+ (BOOL) validateImageAtPath:(NSString *)aFilePath error:(NSError **)outError;

@end


@interface WAFile (CoreDataGeneratedPrimitiveAccessors)

- (void) setPrimitiveResourceFilePath:(NSString *)newResourceFilePath;
- (NSString *) primitiveResourceFilePath;

- (void) setPrimitiveResourceURL:(NSString *)newResourceURL;
- (NSString *) primitiveResourceURL;

- (void) setPrimitiveThumbnailFilePath:(NSString *)newThumbnailFilePath;
- (NSString *) primitiveThumbnailFilePath;

- (void) setPrimitiveThumbnailURL:(NSString *)newThumbnailURL;
- (NSString *) primitiveThumbnailURL;

@end
