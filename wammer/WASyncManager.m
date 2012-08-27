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


@interface WASyncManager ()

@property (nonatomic, readwrite, strong) IRRecurrenceMachine *recurrenceMachine;
@property (nonatomic, readwrite, strong) NSOperationQueue *operationQueue;

@end


@implementation WASyncManager
@synthesize recurrenceMachine = _recurrenceMachine;
@synthesize operationQueue = _operationQueue;

+ (void) load {

	__block id applicationDidFinishLaunchingListener = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
	
		[[NSNotificationCenter defaultCenter] removeObserver:applicationDidFinishLaunchingListener];
		
		[WASyncManager sharedManager];
		
	}];

}

+ (id) sharedManager {

	static dispatch_once_t token = 0;
	static WASyncManager *manager = nil;
	dispatch_once(&token, ^{
		manager = [[self alloc] init];
	});
	
	return manager;

}

- (id) init {

	self = [super init];
	if (!self)
		return nil;
	
	[self reload];

	return self;

}

- (void) dealloc {

	[_operationQueue cancelAllOperations];

	[[NSNotificationCenter defaultCenter] removeObserver:self];

}

- (void)reload {

	[[self recurrenceMachine] scheduleOperationsNow];

	__weak WASyncManager *wSelf = self;

	[self countFilesWithCompletion:^(NSUInteger count) {

		dispatch_async(dispatch_get_main_queue(), ^{

			wSelf.numberOfFiles = count;

		});

	}];

}

- (NSOperationQueue *) operationQueue {

	if (_operationQueue)
		return _operationQueue;
	
	_operationQueue = [[NSOperationQueue alloc] init];
	_operationQueue.maxConcurrentOperationCount = 1;
	
	return _operationQueue;

}

- (IRRecurrenceMachine *) recurrenceMachine {

	if (_recurrenceMachine)
		return _recurrenceMachine;
	
	_recurrenceMachine = [[IRRecurrenceMachine alloc] init];
	_recurrenceMachine.queue.maxConcurrentOperationCount = 1;
	_recurrenceMachine.recurrenceInterval = 5;
	
	[_recurrenceMachine addRecurringOperation:[self fullQualityFileSyncOperationPrototype]];
	[_recurrenceMachine addRecurringOperation:[self dirtyArticleSyncOperationPrototype]];
	
	return _recurrenceMachine;

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
