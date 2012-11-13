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

#import "WASyncManager+FullQualityFileSync.h"
#import "WASyncManager+DirtyArticleSync.h"
#import "WASyncManager+FileMetadataSync.h"


@interface WASyncManager ()

@property (nonatomic, strong) IRRecurrenceMachine *recurrenceMachine;
@property (nonatomic, strong) NSOperationQueue *fileSyncOperationQueue;
@property (nonatomic, strong) NSOperationQueue *fileMetadataSyncOperationQueue;

@end


@implementation WASyncManager

- (id) init {

	self = [super init];

	if (self) {

		self.fileSyncOperationQueue = [[NSOperationQueue alloc] init];
		self.fileSyncOperationQueue.maxConcurrentOperationCount = 1;
		self.fileMetadataSyncOperationQueue = [[NSOperationQueue alloc] init];
		self.fileMetadataSyncOperationQueue.maxConcurrentOperationCount = 1;

		self.recurrenceMachine = [[IRRecurrenceMachine alloc] init];
		self.recurrenceMachine.queue.maxConcurrentOperationCount = 1;
		self.recurrenceMachine.recurrenceInterval = 5;
		[self.recurrenceMachine addRecurringOperation:[self fileMetadataSyncOperation]];
		[self.recurrenceMachine addRecurringOperation:[self dirtyArticleSyncOperationPrototype]];
		[self.recurrenceMachine addRecurringOperation:[self fullQualityFileSyncOperationPrototype]];

		[self reload];

	}

	return self;

}

- (void) dealloc {

	[self.recurrenceMachine.queue cancelAllOperations];
	[self.fileSyncOperationQueue cancelAllOperations];
	[self.fileMetadataSyncOperationQueue cancelAllOperations];

}

- (void)reload {

	if (![NSThread isMainThread]) {
		__weak WASyncManager *wSelf = self;
		dispatch_async(dispatch_get_main_queue(), ^{
			[wSelf reload];
		});
		return;
	}

	[[self recurrenceMachine] scheduleOperationsNow];

	__weak WASyncManager *wSelf = self;

	[self countFilesWithCompletion:^(NSUInteger count) {

		dispatch_async(dispatch_get_main_queue(), ^{

			wSelf.numberOfFiles = count;

		});

	}];

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

@end
