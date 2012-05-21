//
//  WABlobSyncManager.m
//  wammer
//
//  Created by Evadne Wu on 1/4/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WABlobSyncManager.h"

#import "IRRecurrenceMachine.h"
#import "IRAsyncOperation.h"

#import "WARemoteInterface.h"

#import "WAReachabilityDetector.h"

#import "WAFile+WARemoteInterfaceEntitySyncing.h"


@interface WABlobSyncManager ()

@property (readwrite, assign) NSUInteger numberOfFiles;
@property (nonatomic, readwrite, retain) IRRecurrenceMachine *recurrenceMachine;

- (IRAsyncOperation *) haulingOperationPrototype;

@end


@implementation WABlobSyncManager
@synthesize recurrenceMachine, numberOfFiles;

+ (void) load {

	__block id applicationDidFinishLaunchingListener = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
	
		[[NSNotificationCenter defaultCenter] removeObserver:applicationDidFinishLaunchingListener];
		
		[WABlobSyncManager sharedManager];
		
	}];

}

+ (id) sharedManager {

	static dispatch_once_t token = 0;
	static WABlobSyncManager *manager = nil;
	dispatch_once(&token, ^{
		manager = [[self alloc] init];
	});
	
	return manager;

}

- (id) init {

	self = [super init];
	if (!self)
		return nil;
	
	[self recurrenceMachine];
	
	return self;

}

- (void) dealloc {

	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (IRRecurrenceMachine *) recurrenceMachine {

	if (recurrenceMachine)
		return recurrenceMachine;
	
	recurrenceMachine = [[IRRecurrenceMachine alloc] init];
	recurrenceMachine.queue.maxConcurrentOperationCount = 1;
	recurrenceMachine.recurrenceInterval = 30;
	
	[recurrenceMachine addRecurringOperation:[self haulingOperationPrototype]];
	
	return recurrenceMachine;

}

- (void) beginPostponingBlobSync {

	NSParameterAssert(recurrenceMachine);
	[recurrenceMachine beginPostponingOperations];

}

- (void) endPostponingBlobSync {

	NSParameterAssert(recurrenceMachine);
	[recurrenceMachine endPostponingOperations];

}

- (BOOL) isPerformingBlobSync {

	NSParameterAssert(recurrenceMachine);
	return ![recurrenceMachine isPostponingOperations];

}

- (IRAsyncOperation *) haulingOperationPrototype {

	__weak WABlobSyncManager *wSelf = self;
	__weak IRRecurrenceMachine *wRecurrenceMachine = self.recurrenceMachine;

	return [IRAsyncOperation operationWithWorkerBlock: ^ (void(^aCallback)(id)) {
	
		WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
		
		BOOL const endpointAvailable = [ri hasReachableStation] || [ri hasReachableCloud];
		BOOL const hasWiFiConnection = [[WAReachabilityDetector sharedDetectorForLocalWiFi] networkReachable];
		BOOL const canSync = endpointAvailable && hasWiFiConnection;
		
		if (!canSync) {
		
			aCallback(nil);
			return;
		
		}
		
		[wRecurrenceMachine beginPostponingOperations];
	
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
		
			__block NSOperationQueue *tempQueue = [[NSOperationQueue alloc] init];
			
			tempQueue.maxConcurrentOperationCount = 1;
			[tempQueue setSuspended:YES];
			
			__block NSManagedObjectContext *context = nil;	//	Should be created on the operation queue so thread safety is maintained
			__block NSOperation *lastAddedOperation = nil;	//	For dependencies
			
			void (^enqueue)(NSOperation *) = ^ (NSOperation *anOperation){
				if (lastAddedOperation) {
					[anOperation addDependency:lastAddedOperation];
				}
				[tempQueue addOperation:anOperation];
				lastAddedOperation = anOperation;
			};
			
			enqueue([NSBlockOperation blockOperationWithBlock:^{
				context = [[WADataStore defaultStore] disposableMOC];
			}]);

			[[WADataStore defaultStore] enumerateFilesWithSyncableBlobsInContext:nil usingBlock:^(WAFile *aFile, NSUInteger index, BOOL *stop) {
			
				wSelf.numberOfFiles = wSelf.numberOfFiles + 1;
			
				NSURL *fileURL = [[aFile objectID] URIRepresentation];
				
				enqueue([IRAsyncOperation operationWithWorkerBlock:^(void(^callback)(id)) {
				
					WAFile *actualFile = (WAFile *)[context irManagedObjectForURI:fileURL];
					if (!actualFile) {
						callback(nil);
						return;
					}
					
					[actualFile synchronizeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:
						
						kWAFileSyncFullQualityStrategy, kWAFileSyncStrategy,
						
					nil] completion:^(BOOL didFinish, NSManagedObjectContext *context, NSArray *objects, NSError *error) {
						
						callback(didFinish ? (id)kCFBooleanTrue : error);
						
					}];

				} completionBlock:^(id results) {
					
					wSelf.numberOfFiles = wSelf.numberOfFiles - 1;
					
				}]);
				
			}];
			
			enqueue([NSBlockOperation blockOperationWithBlock:^{
			
				context = nil;
				tempQueue = nil;
				
				aCallback(nil);
				
				dispatch_async(dispatch_get_main_queue(), ^{
					
					[wRecurrenceMachine endPostponingOperations];
				
				});
				
			}]);
			
			[tempQueue setSuspended:NO];
			
		});
		
	} completionBlock:nil];

}

@end


@implementation WADataStore (BlobSyncingAdditions)

- (void) enumerateFilesWithSyncableBlobsInContext:(NSManagedObjectContext *)context usingBlock:(void(^)(WAFile *aFile, NSUInteger index, BOOL *stop))block {

	NSParameterAssert(block);

	if (!context)
		context = [self disposableMOC];
	
	NSFetchRequest *fr = [context.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRFilesWithSyncableBlobs" substitutionVariables:[NSDictionary dictionary]];
	
	fr.sortDescriptors = [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
	nil];
	
	[[context executeFetchRequest:fr error:nil] enumerateObjectsUsingBlock: ^ (WAFile *aFile, NSUInteger idx, BOOL *stop) {

		block(aFile, idx, stop);
		
	}];

}

@end
