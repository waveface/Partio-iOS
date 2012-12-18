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

#import <objc/runtime.h>


@implementation WASyncManager (FullQualityFileSync)

- (IRAsyncOperation *) fullQualityFileSyncOperationPrototype {

	__weak WASyncManager *wSelf = self;
	__weak IRRecurrenceMachine *wRecurrenceMachine = self.recurrenceMachine;
	
	__block NSManagedObjectContext *context = nil;
	
	return [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
	
		if (![[NSUserDefaults standardUserDefaults] boolForKey:kWAPhotoImportEnabled]) {
			callback(nil);
			return;
		}
		
		WAPhotoImportManager *photoImportManager = [(WAAppDelegate_iOS *)AppDelegate() photoImportManager];
		if (photoImportManager.preprocessing || photoImportManager.operationQueue.operationCount > 0) {
			callback(nil);
			return;
		}

		if (![[NSUserDefaults standardUserDefaults] boolForKey:kWABackupFilesToPCEnabled]) {
			callback(nil);
			return;
		}

		NSCAssert2(!wSelf.fileSyncOperationQueue.operationCount, @"Operation queue %@ must have 0 operations when the recurrence machine hits, but has %i operations pending",wSelf.fileSyncOperationQueue, wSelf.fileSyncOperationQueue.operationCount);
		
		NSCAssert1(!context, @"Shared context reference should be nil, got %@", context);
		
		BOOL const canSync = [wSelf canPerformBlobSync];
		
		if (!canSync) {
		
			callback(nil);
			return;
		
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[wRecurrenceMachine beginPostponingOperations];
		
		});
		
		WADataStore * const ds = [WADataStore defaultStore];
		
		context = [ds disposableMOC];
		__weak NSManagedObjectContext *wContext = context;
		
		NSMutableArray *syncOperations = [NSMutableArray array];
		
		[context performBlockAndWait:^{
		
			[ds enumerateFilesWithSyncableBlobsInContext:wContext usingBlock:^(WAFile *aFile, NSUInteger index, BOOL *stop) {
			
				[syncOperations addObject:[IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
					
					[aFile synchronizeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
						
						kWAFileSyncFullQualityStrategy, kWAFileSyncStrategy,
						
					nil] completion:^(BOOL didFinish, NSError *error) {
						
						callback(didFinish ? (id)kCFBooleanTrue : error);
						
					}];
					
				} trampoline:^(IRAsyncOperationInvoker block) {
				
					[context performBlock:block];
					
				} callback:^(id results) {
				
				} callbackTrampoline:^(IRAsyncOperationInvoker block) {
					
					[context performBlock:block];
					
				}]];
			
			}];
			
		}];
		
		NSOperation *tailOp = [NSBlockOperation blockOperationWithBlock:^{
			
			context = nil;
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[wRecurrenceMachine endPostponingOperations];
			});
			
			callback(nil);
		}];
		
		for (IRAsyncOperation *op in syncOperations)
			[tailOp addDependency:op];
		
		[syncOperations addObject:tailOp];
		
		[wSelf.fileSyncOperationQueue addOperations:syncOperations waitUntilFinished:NO];
		
	} trampoline:^(IRAsyncOperationInvoker block) {
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
		
	} callback:^(id results) {
	
		//	?
		
	} callbackTrampoline:^(IRAsyncOperationInvoker block) {
	
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
		
	}];

}

- (BOOL) canPerformBlobSync {

	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	
	if (!ri.userToken)
		return NO;
	
//	BOOL const hasReachableCloud = [ri hasReachableCloud];
	BOOL const hasReachableStation = [ri hasReachableStation];
//	BOOL const endpointAvailable = hasReachableStation || hasReachableCloud;
	BOOL const hasWiFiConnection = [ri hasWiFiConnection];
	BOOL const canSync = hasReachableStation && hasWiFiConnection;
	
	return canSync;

}

@end
