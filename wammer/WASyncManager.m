//
//  WASyncManager.m
//  wammer
//
//  Created by Evadne Wu on 1/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASyncManager.h"
#import "IRRecurrenceMachine.h"
#import "Foundation+IRAdditions.h"
#import "WARemoteInterface.h"
#import "WASyncManager+PhotoImport.h"
#import "WASyncManager+FullQualityFileSync.h"
#import "WASyncManager+DirtyArticleSync.h"
#import "WASyncManager+FileMetadataSync.h"
#import "WADefines.h"
#import "WAArticle+WARemoteInterfaceEntitySyncing.h"
#import "WAFile+WARemoteInterfaceEntitySyncing.h"


@interface WASyncManager ()

@property (nonatomic, strong) IRRecurrenceMachine *recurrenceMachine;
@property (nonatomic, strong) NSOperationQueue *articleSyncOperationQueue;
@property (nonatomic, strong) NSOperationQueue *fileSyncOperationQueue;
@property (nonatomic, strong) NSOperationQueue *fileMetadataSyncOperationQueue;
@property (nonatomic, strong) NSOperationQueue *photoImportOperationQueue;
@property (nonatomic) BOOL photoImportEnabled;

@end


@implementation WASyncManager

- (id) init {
  
  self = [super init];
  
  if (self) {
    
    self.photoImportOperationQueue = [[NSOperationQueue alloc] init];
    self.photoImportOperationQueue.maxConcurrentOperationCount = 1;
    
    // article sync runs on concurrent queue because we have to count files needing sync as soon as possible
    self.articleSyncOperationQueue = [[NSOperationQueue alloc] init];

    self.fileSyncOperationQueue = [[NSOperationQueue alloc] init];
    self.fileSyncOperationQueue.maxConcurrentOperationCount = 1;

    self.fileMetadataSyncOperationQueue = [[NSOperationQueue alloc] init];
    self.fileMetadataSyncOperationQueue.maxConcurrentOperationCount = 1;
    
    self.recurrenceMachine = [[IRRecurrenceMachine alloc] init];
    self.recurrenceMachine.queue.maxConcurrentOperationCount = 1;
    self.recurrenceMachine.recurrenceInterval = 5;
    
    __weak WASyncManager *wSelf = self;
    [self.recurrenceMachine addRecurringOperation:[NSBlockOperation blockOperationWithBlock:^{
      wSelf.isSyncFail = NO;
      wSelf.needingImportFilesCount = 0;
      wSelf.importedFilesCount = 0;
      wSelf.needingSyncFilesCount = 0;
      wSelf.syncedFilesCount = 0;
    }]];
    [self.recurrenceMachine addRecurringOperation:[self photoImportOperationPrototype]];
    [self.recurrenceMachine addRecurringOperation:[self fileMetadataSyncOperationPrototype]];
    [self.recurrenceMachine addRecurringOperation:[self dirtyArticleSyncOperationPrototype]];
    [self.recurrenceMachine addRecurringOperation:[self fullQualityFileSyncOperationPrototype]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserDefaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    
  }
  
  return self;
  
}

- (void) dealloc {
  
  // other queues will be automatically released (and operations are canceled),
  // so we only need to cancel operations in the two share sync queues
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [[WAArticle sharedSyncQueue] cancelAllOperations];
    [[WAFile sharedSyncQueue] cancelAllOperations];
  });
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
 
}

- (void)reload {
  
  [[self recurrenceMachine] scheduleOperationsNow];

}

- (void) beginPostponingSync {
  
  NSParameterAssert(_recurrenceMachine);
  [_recurrenceMachine beginPostponingOperations];
  
}

- (void) endPostponingSync {
  
  NSParameterAssert(_recurrenceMachine);
  [_recurrenceMachine endPostponingOperations];
  
}

- (void)waitUntilFinished {

  [self.recurrenceMachine.queue waitUntilAllOperationsAreFinished];
  [self.photoImportOperationQueue waitUntilAllOperationsAreFinished];
  [self.articleSyncOperationQueue waitUntilAllOperationsAreFinished];
  [self.fileSyncOperationQueue waitUntilAllOperationsAreFinished];
  [self.fileMetadataSyncOperationQueue waitUntilAllOperationsAreFinished];
  [[WAArticle sharedSyncQueue] waitUntilAllOperationsAreFinished];
  [[WAFile sharedSyncQueue] waitUntilAllOperationsAreFinished];

}

- (void)cancelAllOperations {

  [self.recurrenceMachine.queue cancelAllOperations];
  [self.photoImportOperationQueue cancelAllOperations];
  [self.articleSyncOperationQueue cancelAllOperations];
  [self.fileSyncOperationQueue cancelAllOperations];
  [self.fileMetadataSyncOperationQueue cancelAllOperations];
  [[WAArticle sharedSyncQueue] cancelAllOperations];
  [[WAFile sharedSyncQueue] cancelAllOperations];
  
}

+ (NSSet *)keyPathsForValuesAffectingIsSyncing {

  return [NSSet setWithArray:@[
	@"importedFilesCount",
	@"syncedFilesCount",
	@"photoImportOperationQueue.operationCount",
	@"articleSyncOperationQueue.operationCount"
	]];
}

- (void)setIsSyncFail:(BOOL)isSyncFail {

  if (_isSyncFail != isSyncFail) {
    _isSyncFail = isSyncFail;
    [self cancelWithRecovery];
  }

}

- (BOOL)isSyncing {

  if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
    return NO;
  }
  
  // there will be at least one tail op if any sync operation exists in these op queue,
  // and metadata sync will not show on status bar
  return (([self.photoImportOperationQueue operationCount] > 1) ||
	([self.articleSyncOperationQueue operationCount] > 1));

}

- (void)cancelWithRecovery {

  __weak WASyncManager *wSelf = self;
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
    [wSelf cancelAllOperations];
    [wSelf waitUntilFinished];
    
    // reset postponing counter because the operations decreasing the postponing count
    // might be canceled by the method
    dispatch_sync(dispatch_get_main_queue(), ^{
      while ([wSelf.recurrenceMachine isPostponingOperations]) {
        [wSelf.recurrenceMachine endPostponingOperations];
      }
    });
    
  });

}

#pragma mark - Target actions

- (void)handleUserDefaultsChanged:(NSNotification *)notification {
  
  NSUserDefaults *defaults = [notification object];
  if (self.photoImportEnabled != [defaults boolForKey:kWAPhotoImportEnabled]) {
    self.photoImportEnabled = [defaults boolForKey:kWAPhotoImportEnabled];
    if (self.photoImportEnabled) {
      [self reload];
    } else {
      [self cancelWithRecovery];
    }
  }

}

@end
