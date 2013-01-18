//
//  WASyncManager+FullQualityFileSync.m
//  wammer
//
//  Created by Evadne Wu on 6/21/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WASyncManager+FullQualityFileSync.h"
#import "Foundation+IRAdditions.h"
#import "IRRecurrenceMachine.h"
#import "WARemoteInterface.h"
#import "WADataStore+WASyncManagerAdditions.h"
#import "WAFile+WARemoteInterfaceEntitySyncing.h"
#import "WAAppDelegate_iOS.h"
#import "WADefines+iOS.h"
#import "WADefines.h"

@implementation WASyncManager (FullQualityFileSync)

- (IRAsyncOperation *) fullQualityFileSyncOperationPrototype {
  
  __weak WASyncManager *wSelf = self;
  
  return [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
    
    if (![wSelf canPerformBlobSync]) {
      callback(nil);
      return;
    }
    
    [wSelf beginPostponingSync];

    NSMutableArray *operations = [NSMutableArray array];
    [[WADataStore defaultStore] enumerateFilesWithSyncableBlobsInContext:nil usingBlock:^(WAFile *aFile, NSUInteger index, BOOL *stop) {
      
      NSURL *ownURL = [[aFile objectID] URIRepresentation];

      IRAsyncBarrierOperation *operation = [IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

        NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
        WAFile *file = (WAFile *)[context irManagedObjectForURI:ownURL];
        
        [file synchronizeWithOptions:@{kWAFileSyncStrategy: kWAFileSyncFullQualityStrategy}
		       completion:^(BOOL didFinish, NSError *error) {

		         if (error) {
			 NSLog(@"Unable to sync original file, error: %@", error);
		         }
		         
		         callback(error);
		         
		       }];
        
      } trampoline:^(IRAsyncOperationInvoker callback) {

        NSCAssert(![NSThread isMainThread], @"should run in background");
        callback();

      } callback:^(id results) {

        // NO OP

      } callbackTrampoline:^(IRAsyncOperationInvoker callback) {

        NSCAssert(![NSThread isMainThread], @"should run in background");
        callback();

      }];

      [operations addObject:operation];

    }];

    IRAsyncBarrierOperation *tailOp = [IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
      // NO OP
    } trampoline:^(IRAsyncOperationInvoker callback) {
      NSCAssert(![NSThread isMainThread], @"should run in background");
      callback();
    } callback:^(id results) {
      // -[WASyncManager endPostponingSync] must be called no matter the operations are succeed or not
      [wSelf endPostponingSync];
    } callbackTrampoline:^(IRAsyncOperationInvoker callback) {
      NSCAssert(![NSThread isMainThread], @"should run in background");
      callback();
    }];

    [operations addObject:tailOp];

    [operations enumerateObjectsUsingBlock:^(IRAsyncBarrierOperation *op, NSUInteger idx, BOOL *stop) {
      if (idx > 0)
        [op addDependency:(IRAsyncBarrierOperation *)operations[(idx - 1)]];
    }];
    
    IRAsyncOperation *lastOperation = [[wSelf.fileSyncOperationQueue operations] lastObject];
    if (lastOperation) {
      [operations[0] addDependency:lastOperation];
    }
    
    [wSelf.fileSyncOperationQueue addOperations:operations waitUntilFinished:NO];
    
    callback(nil);
    
  } trampoline:^(IRAsyncOperationInvoker block) {
    
    NSCAssert(![NSThread isMainThread], @"should run in background");
    block();
    
  } callback:^(id results) {
    
    // NO OP
    
  } callbackTrampoline:^(IRAsyncOperationInvoker block) {
    
    NSCAssert(![NSThread isMainThread], @"should run in background");
    block();
    
  }];
  
}

- (BOOL) canPerformBlobSync {
  
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
    return NO;
  }
  
  WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
  if (!ri.userToken) {
    return NO;
  }
  
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAUseCellularEnabled] && ![ri hasWiFiConnection]) {
    return NO;
  }

  BOOL const hasReachableCloud = [ri hasReachableCloud];
  BOOL const hasReachableStation = [ri hasReachableStation];
  
  if ([[NSUserDefaults standardUserDefaults] boolForKey:kWABackupFilesToCloudEnabled]) {
    return hasReachableStation || hasReachableCloud;
  } else {
    return hasReachableStation;
  }
  
}

@end
