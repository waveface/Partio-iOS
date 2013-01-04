//
//  WASyncManager.h
//  wammer
//
//  Created by Evadne Wu on 1/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WADataStore.h"

@class IRRecurrenceMachine;
@interface WASyncManager : NSObject

- (void) beginPostponingSync;
- (void) endPostponingSync;

- (void) reload;

- (void) waitUntilFinished;

@property (nonatomic, readonly, strong) NSOperationQueue *articleSyncOperationQueue;
@property (nonatomic, readonly, strong) NSOperationQueue *fileSyncOperationQueue;
@property (nonatomic, readonly, strong) NSOperationQueue *fileMetadataSyncOperationQueue;
@property (nonatomic, readonly, strong) NSOperationQueue *photoImportOperationQueue;

@property (nonatomic) NSUInteger needingSyncFilesCount;
@property (nonatomic) NSUInteger syncedFilesCount;
@property (nonatomic) NSUInteger needingImportFilesCount;
@property (nonatomic) NSUInteger importedFilesCount;

@property (nonatomic, readonly) BOOL isSyncing;
@property (nonatomic) BOOL isSyncFail;

@end
