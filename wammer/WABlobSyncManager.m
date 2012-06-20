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

@property (nonatomic, readwrite, assign) NSUInteger numberOfFiles;
@property (nonatomic, readwrite, strong) IRRecurrenceMachine *recurrenceMachine;
@property (nonatomic, readwrite, strong) NSOperationQueue *operationQueue;

- (IRAsyncOperation *) haulingOperationPrototype;

- (void) countFilesWithCompletion:(void(^)(NSUInteger count))block;
- (void) countFilesInContext:(NSManagedObjectContext *)context withCompletion:(void(^)(NSUInteger count))block;

@end


@implementation WABlobSyncManager
@synthesize recurrenceMachine, numberOfFiles;
@synthesize operationQueue;

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
	
	[[self recurrenceMachine] scheduleOperationsNow];
	
	//	[[WARemoteInterface sharedInterface] irObserve:@"networkState" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil withBlock:^(NSKeyValueChange kind, id fromValue, id toValue, NSIndexSet *indices, BOOL isPrior) {
	//		
	//		NSLog(@"networkState -> %@ — kind %i, from %@, indices %@, isPrior %x", toValue, kind, fromValue, indices, isPrior);
	//
	//	}];
		
	__weak WABlobSyncManager *wSelf = self;
	
	[self.operationQueue addOperations:[NSArray arrayWithObject:[NSBlockOperation blockOperationWithBlock:^{
		
		[wSelf countFilesWithCompletion:^(NSUInteger count) {
		
			dispatch_async(dispatch_get_main_queue(), ^{

				wSelf.numberOfFiles = count;
				
			});
			
		}];
		
	}]] waitUntilFinished:YES];
	
	return self;

}

- (void) dealloc {

	[operationQueue cancelAllOperations];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (NSOperationQueue *) operationQueue {

	if (operationQueue)
		return operationQueue;
	
	operationQueue = [[NSOperationQueue alloc] init];
	operationQueue.maxConcurrentOperationCount = 1;
	
	return operationQueue;

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

- (BOOL) canPerformBlobSync {

	WARemoteInterface * const ri = [WARemoteInterface sharedInterface];
	
	BOOL const hasReachableCloud = [ri hasReachableCloud];
	BOOL const hasReachableStation = [ri hasReachableStation];
	BOOL const endpointAvailable = hasReachableStation || hasReachableCloud;
	BOOL const hasWiFiConnection = [ri hasWiFiConnection];
	BOOL const canSync = endpointAvailable && hasWiFiConnection;
	
	return canSync;

}

- (void) performBlobSyncNow {
	
	[[self recurrenceMachine] scheduleOperationsNow];
	
}

- (void) setNumberOfFiles:(NSUInteger)newNumberOfFiles {

	NSCParameterAssert([NSThread isMainThread]);
		
	numberOfFiles = newNumberOfFiles;

}

- (IRAsyncOperation *) haulingOperationPrototype {

	__weak WABlobSyncManager *wSelf = self;
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

- (void) countFilesWithCompletion:(void (^)(NSUInteger))block {

	[self countFilesInContext:nil withCompletion:block];

}

- (void) countFilesInContext:(NSManagedObjectContext *)context withCompletion:(void (^)(NSUInteger))block {

	WADataStore *ds = [WADataStore defaultStore];
	NSManagedObjectContext *usedContext = context ? context : [ds disposableMOC];
	
	block([ds numberOfFilesWithSyncableBlobsInContext:usedContext]);

}

@end


@implementation WADataStore (BlobSyncingAdditions)

- (NSFetchRequest *) fetchRequestForFilesWithSyncableBlobsInContext:(NSManagedObjectContext *)context {

	return [context.persistentStoreCoordinator.managedObjectModel fetchRequestFromTemplateWithName:@"WAFRFilesWithSyncableBlobs" substitutionVariables:[NSDictionary dictionary]];

}

- (void) enumerateFilesWithSyncableBlobsInContext:(NSManagedObjectContext *)context usingBlock:(void(^)(WAFile *aFile, NSUInteger index, BOOL *stop))block {

	NSParameterAssert(block);

	if (!context)
		context = [self disposableMOC];
	
	NSFetchRequest *fr = [self fetchRequestForFilesWithSyncableBlobsInContext:context];
	
	fr.sortDescriptors = [NSArray arrayWithObjects:
		[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO],
	nil];
	
	NSArray *files = [context executeFetchRequest:fr error:nil];
	
	[files enumerateObjectsUsingBlock: ^ (WAFile *aFile, NSUInteger idx, BOOL *stop) {
		
		block(aFile, idx, stop);
		
	}];

}

- (NSUInteger) numberOfFilesWithSyncableBlobsInContext:(NSManagedObjectContext *)context {

	if (!context)
		context = [self disposableMOC];
	
	NSFetchRequest *fr = [self fetchRequestForFilesWithSyncableBlobsInContext:context];
	
	fr.includesPendingChanges = NO;
	fr.includesPropertyValues = NO;
	fr.includesSubentities = NO;
	
	return [context countForFetchRequest:fr error:nil];
	
}

@end
