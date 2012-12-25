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
@dynamic syncCompleted, syncStopped;

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
    [self.recurrenceMachine addRecurringOperation:[self photoImportOperation]];
    [self.recurrenceMachine addRecurringOperation:[self dirtyArticleSyncOperationPrototype]];
    [self.recurrenceMachine addRecurringOperation:[self fullQualityFileSyncOperationPrototype]];
    [self.recurrenceMachine addRecurringOperation:[self fileMetadataSyncOperation]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUserDefaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];

    [self reload];
    
  }
  
  return self;
  
}

- (void) dealloc {
  
  [self.recurrenceMachine.queue cancelAllOperations];
  [self.photoImportOperationQueue cancelAllOperations];
  [self.articleSyncOperationQueue cancelAllOperations];
  [self.fileSyncOperationQueue cancelAllOperations];
  [self.fileMetadataSyncOperationQueue cancelAllOperations];

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

- (void) performSyncNow {
  
  [[self recurrenceMachine] scheduleOperationsNow];
  
}

- (BOOL)syncCompleted {
  
  return (self.needingSyncFilesCount == self.syncedFilesCount && self.needingSyncFilesCount != 0);
  
}

- (BOOL)syncStopped {
  
  return (self.needingSyncFilesCount == self.syncedFilesCount && self.needingSyncFilesCount == 0);
  
}

- (void)resetSyncFilesCount {
  
  self.syncedFilesCount = 0;
  self.needingSyncFilesCount = 0;
  
}

- (BOOL)importCompleted {
  
  return (self.needingImportFilesCount == self.importedFilesCount && self.needingImportFilesCount != 0);
  
}

- (BOOL)importStopped {
  
  return (self.needingSyncFilesCount == self.syncedFilesCount && self.needingSyncFilesCount == 0);
  
}

- (void)resetImportedFilesCount {
  
  self.needingImportFilesCount = 0;
  self.importedFilesCount = 0;
  
}

- (void)waitUntilFinished {

  [self.photoImportOperationQueue waitUntilAllOperationsAreFinished];
  [self.articleSyncOperationQueue waitUntilAllOperationsAreFinished];
  [self.fileSyncOperationQueue waitUntilAllOperationsAreFinished];
  [self.fileMetadataSyncOperationQueue waitUntilAllOperationsAreFinished];

}

#pragma mark - Target actions

- (void)handleUserDefaultsChanged:(NSNotification *)notification {
  
  NSUserDefaults *defaults = [notification object];
  if (self.photoImportEnabled != [defaults boolForKey:kWAPhotoImportEnabled]) {
    self.photoImportEnabled = [defaults boolForKey:kWAPhotoImportEnabled];
    if (self.photoImportEnabled) {
      [self reload];
    } else {
      [self.photoImportOperationQueue cancelAllOperations];
      [self.photoImportOperationQueue waitUntilAllOperationsAreFinished];
    }
  }

}

@end
