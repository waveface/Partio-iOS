//
//  WASyncManager.m
//  wammer
//
//  Created by Evadne Wu on 1/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "IRRecurrenceMachine.h"
#import "Foundation+IRAdditions.h"

#import "WASyncManager.h"
#import "WARemoteInterface.h"
#import "WAReachabilityDetector.h"

#import "WASyncManager+PhotoImport.h"
#import "WASyncManager+FullQualityFileSync.h"
#import "WASyncManager+DirtyArticleSync.h"
#import "WASyncManager+FileMetadataSync.h"
#import "WADefines.h"


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
    [self.recurrenceMachine addRecurringOperation:[self photoImportOperation]];
    [self.recurrenceMachine addRecurringOperation:[self dirtyArticleSyncOperationPrototype]];
    [self.recurrenceMachine addRecurringOperation:[self fullQualityFileSyncOperationPrototype]];
    [self.recurrenceMachine addRecurringOperation:[self fileMetadataSyncOperation]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserDefaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    
  }
  
  return self;
  
}

- (void) dealloc {
  
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

}

- (void)cancelAllOperations {

  if ([NSThread isMainThread]) {
    __weak WASyncManager *wSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [wSelf cancelAllOperations];
    });
    return;
  }

  // it possibly takes long time to wait until all operations finished
  [self.recurrenceMachine.queue cancelAllOperations];
  [self.photoImportOperationQueue cancelAllOperations];
  [self.articleSyncOperationQueue cancelAllOperations];
  [self.fileSyncOperationQueue cancelAllOperations];
  [self.fileMetadataSyncOperationQueue cancelAllOperations];

  [self waitUntilFinished];
  
  // reset postponing counter because the operations decreasing the postponing count
  // might be canceled by the method
  __weak WASyncManager *wSelf = self;  
  dispatch_sync(dispatch_get_main_queue(), ^{
    while ([wSelf.recurrenceMachine isPostponingOperations]) {
      [wSelf.recurrenceMachine endPostponingOperations];
    }
  });

}

+ (NSSet *)keyPathsForValuesAffectingIsSyncing {

  return [NSSet setWithArray:@[
	@"importedFilesCount",
	@"syncedFilesCount",
	@"photoImportOperationQueue.operationCount",
	@"articleSyncOperationQueue.operationCount",
	@"fileSyncOperationQueue.operationCount",
	@"fileMetadataSyncOperationQueue.operationCount"
	]];
}

- (BOOL)isSyncing {

  if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
    return NO;
  }
  
  return ([self.photoImportOperationQueue operationCount] ||
	[self.articleSyncOperationQueue operationCount] ||
	[self.fileSyncOperationQueue operationCount] ||
	[self.fileMetadataSyncOperationQueue operationCount]);

}

#pragma mark - Target actions

- (void)handleUserDefaultsChanged:(NSNotification *)notification {
  
  NSParameterAssert([NSThread isMainThread]);
  
  NSUserDefaults *defaults = [notification object];
  if (self.photoImportEnabled != [defaults boolForKey:kWAPhotoImportEnabled]) {
    self.photoImportEnabled = [defaults boolForKey:kWAPhotoImportEnabled];
    if (self.photoImportEnabled) {
      [self reload];
    } else {
      [self cancelAllOperations];
    }
  }

}

@end
