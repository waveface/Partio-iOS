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
    
    [[wSelf recurrenceMachine] beginPostponingOperations];

    [[WADataStore defaultStore] enumerateFilesWithSyncableBlobsInContext:nil usingBlock:^(WAFile *aFile, NSUInteger index, BOOL *stop) {
      
      IRAsyncBarrierOperation *operation = [IRAsyncBarrierOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

        [aFile synchronizeWithOptions:@{kWAFileSyncStrategy: kWAFileSyncFullQualityStrategy}
		       completion:^(BOOL didFinish, NSError *error) {

		         if (error) {
			 NSLog(@"Unable to sync original file, error: %@", error);
		         }
		         
		         callback(error);
		         
		       }];
        
      } trampoline:^(IRAsyncOperationInvoker callback) {

        NSParameterAssert(![NSThread isMainThread]);
        callback();

      } callback:^(id results) {

        // NO OP

      } callbackTrampoline:^(IRAsyncOperationInvoker callback) {

        NSParameterAssert(![NSThread isMainThread]);
        callback();

      }];

      [wSelf.fileSyncOperationQueue addOperation:operation];

    }];

    NSBlockOperation *tailOp = [NSBlockOperation blockOperationWithBlock:^{
      [[wSelf recurrenceMachine] endPostponingOperations];
    }];
    
    for (NSOperation *operation in wSelf.fileSyncOperationQueue.operations) {
      [tailOp addDependency:operation];
    }
    
    [wSelf.fileSyncOperationQueue addOperation:tailOp];
    
    callback(nil);
    
  } trampoline:^(IRAsyncOperationInvoker block) {
    
    NSParameterAssert(![NSThread isMainThread]);
    block();
    
  } callback:^(id results) {
    
    // NO OP
    
  } callbackTrampoline:^(IRAsyncOperationInvoker block) {
    
    NSParameterAssert(![NSThread isMainThread]);
    block();
    
  }];
  
}

- (BOOL) canPerformBlobSync {
  
  WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
  
  if (!ri.userToken) {
    return NO;
  }
  
  if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
    return NO;
  }
  
  WAPhotoImportManager *photoImportManager = [(WAAppDelegate_iOS *)AppDelegate() photoImportManager];
  if (photoImportManager.preprocessing || photoImportManager.operationQueue.operationCount > 0) {
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
