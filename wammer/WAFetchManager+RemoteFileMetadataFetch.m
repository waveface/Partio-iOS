//
//  WAFetchManager+RemoteFileMetadataFetch.m
//  wammer
//
//  Created by kchiu on 12/12/27.
//  Copyright (c) 2012年 Waveface. All rights reserved.
//

#import "WAFetchManager+RemoteFileMetadataFetch.h"
#import "Foundation+IRAdditions.h"
#import "WARemoteInterface.h"
#import "WADataStore.h"

@implementation WAFetchManager (RemoteFileMetadataFetch)

- (IRAsyncOperation *)remoteFileMetadataFetchOperationPrototype {

  __weak WAFetchManager *wSelf = self;
  
  IRAsyncOperation *operation = [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

    if (![wSelf canPerformFileMetadataFetch]) {
      callback(nil);
      return;
    }
    
    [wSelf beginPostponingFetch];
    
    const NSUInteger MAX_UPDATING_FILES_COUNT = 50;
    NSMutableArray *updatingFiles = [NSMutableArray array];
    WADataStore *ds = [WADataStore defaultStore];
    NSArray *files = [ds fetchFilesRequireMetaUpdateUsingContext:[ds disposableMOC]];
    [files enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      
      [updatingFiles addObject:[obj identifier]];
      
      if ([updatingFiles count] == MAX_UPDATING_FILES_COUNT || idx == [files count] - 1) {
        
        NSArray *updatingFilesCopy = [NSArray arrayWithArray:updatingFiles];
        IRAsyncOperation *operation = [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {

	[[WARemoteInterface sharedInterface] retrieveMetaForAttachments:updatingFilesCopy onSuccess:^(NSArray *attachmentReps) {
	  
	  [ds performBlock:^{

	    NSManagedObjectContext *context = [ds autoUpdatingMOC];
	    context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	    [WAFile insertOrUpdateObjectsUsingContext:context
			       withRemoteResponse:attachmentReps
				   usingMapping:nil
				        options:IRManagedObjectOptionIndividualOperations];
	    [context save:nil];
	    
	  } waitUntilDone:YES];

	  callback(nil);	  

	} onFailure:^(NSError *error) {
	  
	  NSLog(@"Unable to retrieve attachment metas:%@ error:%@", updatingFiles, error);
	  
	  callback(error);
	  
	}];
	
        } trampoline:^(IRAsyncOperationInvoker callback) {

	NSCParameterAssert(![NSThread isMainThread]);
	callback();

        } callback:^(id results) {

	// NO OP

        } callbackTrampoline:^(IRAsyncOperationInvoker callback) {

	NSCParameterAssert(![NSThread isMainThread]);
	callback();

        }];
        
        [wSelf.fileMetadataFetchOperationQueue addOperation:operation];
        
        [updatingFiles removeAllObjects];
        
      }
      
    }];
    
    NSOperation *tailOp = [NSBlockOperation blockOperationWithBlock:^{
      [wSelf endPostponingFetch];
    }];
    
    for (NSOperation *operation in [wSelf.fileMetadataFetchOperationQueue operations]) {
      [tailOp addDependency:operation];
    }
    
    [wSelf.fileMetadataFetchOperationQueue addOperation:tailOp];
    
    callback(nil);

  } trampoline:^(IRAsyncOperationInvoker callback) {

    NSCParameterAssert(![NSThread isMainThread]);
    callback();

  } callback:^(id results) {

    // NO OP

  } callbackTrampoline:^(IRAsyncOperationInvoker callback) {

    NSCParameterAssert(![NSThread isMainThread]);
    callback();

  }];

  return operation;

}

- (BOOL)canPerformFileMetadataFetch {

  WARemoteInterface *ri = [WARemoteInterface sharedInterface];

  if (!ri.userToken) {
    return NO;
  }

  return YES;

}

@end
