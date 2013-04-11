//
//  WAFetchManager.m
//  wammer
//
//  Created by kchiu on 12/12/27.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFetchManager.h"
#import "IRRecurrenceMachine.h"
#import "Foundation+IRAdditions.h"
#import "WAFetchManager+RemoteIndexFetch.h"
#import "WAFetchManager+RemoteArticlesFetch.h"
#import "WAFetchManager+RemoteCollectionFetch.h"
#import "WAFetchManager+RemoteChangeFetch.h"
#import "WAFetchManager+RemoteFileMetadataFetch.h"
#import "WADefines.h"

@interface WAFetchManager ()

@property (nonatomic, strong) IRRecurrenceMachine *recurrenceMachine;
@property (nonatomic, strong) NSOperationQueue *articleFetchOperationQueue;
@property (nonatomic, strong) NSOperationQueue *fileMetadataFetchOperationQueue;
@property (nonatomic, strong) NSOperationQueue *collectionInsertOperationQueue;
@property (nonatomic, strong) NSDate *currentDate;

@end

@implementation WAFetchManager

- (id)init {

  self = [super init];

  if (self) {

    self.currentDate = [NSDate date];
	
    self.articleFetchOperationQueue = [[NSOperationQueue alloc] init];
    [self.articleFetchOperationQueue setMaxConcurrentOperationCount:1];
    
    // file metadata can be concurrently fetched
    self.fileMetadataFetchOperationQueue = [[NSOperationQueue alloc] init];
    self.collectionInsertOperationQueue = [[NSOperationQueue alloc] init];
    self.collectionInsertOperationQueue.maxConcurrentOperationCount = 1;

    self.recurrenceMachine = [[IRRecurrenceMachine alloc] init];
    [self.recurrenceMachine.queue setMaxConcurrentOperationCount:1];
    self.recurrenceMachine.recurrenceInterval = 10;

//    [self.recurrenceMachine addRecurringOperation:[self remoteCollectionFetchOperationPrototype]];
//    [self.recurrenceMachine addRecurringOperation:[self remoteIndexFetchOperationPrototype]];
    [self.recurrenceMachine addRecurringOperation:[self remoteArticlesFetchOperationPrototype]];
    [self.recurrenceMachine addRecurringOperation:[self remoteChangeFetchOperationPrototype]];
    [self.recurrenceMachine addRecurringOperation:[self remoteFileMetadataFetchOperationPrototype]];

  }

  return self;

}

- (void)reload {

  [self.recurrenceMachine scheduleOperationsNow];

}

- (void)beginPostponingFetch {

  NSParameterAssert(self.recurrenceMachine);
  [self.recurrenceMachine beginPostponingOperations];
  
}

- (void)endPostponingFetch {

  NSParameterAssert(self.recurrenceMachine);
  [self.recurrenceMachine endPostponingOperations];

}

- (void) cancelAllOperations {
  
  [self.recurrenceMachine.queue cancelAllOperations];
  [self.articleFetchOperationQueue cancelAllOperations];
  [self.fileMetadataFetchOperationQueue cancelAllOperations];
  [self.collectionInsertOperationQueue cancelAllOperations];
  
}

- (void)waitUntilFinished {
  
  [self.recurrenceMachine.queue waitUntilAllOperationsAreFinished];
  [self.articleFetchOperationQueue waitUntilAllOperationsAreFinished];
  [self.fileMetadataFetchOperationQueue waitUntilAllOperationsAreFinished];
  [self.collectionInsertOperationQueue waitUntilAllOperationsAreFinished];
  
}

- (void)cancelWithRecovery {
  
  __weak WAFetchManager *wSelf = self;
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

+ (NSSet *)keyPathsForValuesAffectingIsFetching {

  return [NSSet setWithArray:@[
	@"fileMetadataFetchOperationQueue.operationCount"
	]];

}

- (BOOL)isFetching {

  if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAFirstArticleFetched]) {
    return YES;
  }
  
  // there will be at least one tail op if any fetch operation exists in these op queue
  return ([self.fileMetadataFetchOperationQueue operationCount] > 1);

}

@end
