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
#import "WAFetchManager+RemoteArticleFetch.h"
#import "WAFetchManager+RemoteCollectionFetch.h"
#import "WAFetchManager+RemoteChangeFetch.h"
#import "WAFetchManager+RemoteFileMetadataFetch.h"

@interface WAFetchManager ()

@property (nonatomic, strong) IRRecurrenceMachine *recurrenceMachine;
@property (nonatomic, strong) NSOperationQueue *articleFetchOperationQueue;
@property (nonatomic, strong) NSOperationQueue *fileMetadataFetchOperationQueue;

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

    self.recurrenceMachine = [[IRRecurrenceMachine alloc] init];
    [self.recurrenceMachine.queue setMaxConcurrentOperationCount:1];
    self.recurrenceMachine.recurrenceInterval = 10;

    [self.recurrenceMachine addRecurringOperation:[self remoteCollectionFetchOperationPrototype]];
    [self.recurrenceMachine addRecurringOperation:[self remoteArticleFetchOperationPrototype]];
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

@end
