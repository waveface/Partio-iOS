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

#import <objc/runtime.h>

static NSString * const kNumberOfFiles = @"-[WASyncManager(FullQualityFileSync) numberOfFiles]";


@implementation WASyncManager (FullQualityFileSync)

- (IRAsyncOperation *) fullQualityFileSyncOperationPrototype {

	__weak WASyncManager *wSelf = self;
	__weak IRRecurrenceMachine *wRecurrenceMachine = self.recurrenceMachine;
	
	__block NSManagedObjectContext *context = nil;
	
	return [IRAsyncOperation operationWithWorker:^(IRAsyncOperationCallback callback) {
	
		NSCAssert2(!wSelf.operationQueue.operationCount, @"Operation queue %@ must have 0 operations when the recurrence machine hits, but has %i operations pending",wSelf.operationQueue, wSelf.operationQueue.operationCount);
		
		NSCAssert1(!context, @"Shared context reference should be nil, got %@", context);
		
		BOOL const canSync = [wSelf canPerformBlobSync];
		
		[wSelf countFilesWithCompletion:^(NSUInteger count) {
			
			dispatch_async(dispatch_get_main_queue(), ^{
				
				wSelf.numberOfFiles = count;
				
			});
			
		}];

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
		
			[wSelf countFilesInContext:wContext withCompletion:^(NSUInteger count) {
			
				dispatch_async(dispatch_get_main_queue(), ^{
					
					wSelf.numberOfFiles = count;
					
				});

			}];

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
				
					[wSelf countFilesInContext:wContext withCompletion:^(NSUInteger count) {
					
						dispatch_async(dispatch_get_main_queue(), ^{
							
							wSelf.numberOfFiles = count;
							
						});

					}];
					
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
		
		[wSelf.operationQueue addOperations:syncOperations waitUntilFinished:NO];
		
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
	
	BOOL const hasReachableCloud = [ri hasReachableCloud];
	BOOL const hasReachableStation = [ri hasReachableStation];
	BOOL const endpointAvailable = hasReachableStation || hasReachableCloud;
	BOOL const hasWiFiConnection = [ri hasWiFiConnection];
	BOOL const canSync = endpointAvailable && hasWiFiConnection;
	
	return canSync;

}

- (void) countFilesWithCompletion:(void (^)(NSUInteger))block {

	[self countFilesInContext:nil withCompletion:block];

}

- (void) countFilesInContext:(NSManagedObjectContext *)context withCompletion:(void (^)(NSUInteger))block {

	WADataStore *ds = [WADataStore defaultStore];
	NSManagedObjectContext *usedContext = context ? context : [ds disposableMOC];
	
	block([ds numberOfFilesWithSyncableBlobsInContext:usedContext]);

}

- (void) setNumberOfFiles:(NSUInteger)numberOfFiles {

	objc_setAssociatedObject(self, &kNumberOfFiles, [NSNumber numberWithUnsignedInteger:numberOfFiles], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

- (NSUInteger) numberOfFiles {

	return [objc_getAssociatedObject(self, &kNumberOfFiles) unsignedIntegerValue];

}

@end
