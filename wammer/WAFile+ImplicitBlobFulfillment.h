//
//  WAFile+ImplicitBlobFulfillment.h
//  wammer
//
//  Created by Evadne Wu on 5/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAFile.h"

@interface WAFile (ImplicitBlobFulfillment)

@property (nonatomic, readonly, assign) BOOL attemptsBlobRetrieval;
@property (nonatomic, readwrite, assign) BOOL displayingSmallThumbnail;
@property (nonatomic, readwrite, assign) BOOL displayingThumbnail;

- (void) setAttemptsBlobRetrieval:(BOOL)attemptsBlobRetrieval notify:(BOOL) firesKVONotifications;

- (void) performBlockSuppressingBlobRetrieval:(void(^)(void))aBlock;

- (void) retrieveBlobWithURLString:(NSString *)urlString URLStringKey:(NSString *)urlStringKey filePathKey:(NSString *)filePathKey;

- (void) scheduleRetrievalForBlobURL:(NSURL *)blobURL blobKeyPath:(NSString *)blobURLKeyPath filePathKeyPath:(NSString *)filePathKeyPath usingPriority:(NSOperationQueuePriority)priority;

- (BOOL) takeBlobFromTemporaryFile:(NSString *)aPath forKeyPath:(NSString *)fileKeyPath matchingURL:(NSURL *)anURL forKeyPath:(NSString *)urlKeyPath;

@end
