//
//  WARemoteInterface+ScheduledDataRetrieval.m
//  wammer
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <objc/runtime.h>
#import "WARemoteInterface+ScheduledDataRetrieval.h"
#import "WADataStore+WARemoteInterfaceAdditions.h"

#import "WAAppDelegate.h"
#import "WADefines.h"

@interface WARemoteInterface (ScheduledDataRetrieval_Private)

@property (nonatomic, readonly, assign, getter=isPerformingAutomaticRemoteUpdates) BOOL performingAutomaticRemoteUpdates;	//	KVO-able for manual refreshing buttons
@property (nonatomic, readwrite, assign) NSTimeInterval dataRetrievalInterval;
@property (nonatomic, readwrite, retain) NSArray *dataRetrievalBlocks;
@property (nonatomic, readwrite, retain) NSTimer *dataRetrievalTimer;
@property (nonatomic, readwrite, assign) int dataRetrievalTimerPostponingCount;
@property (nonatomic, readwrite, assign) int automaticRemoteUpdatesPerformingCount;

@end


@implementation WARemoteInterface (ScheduledDataRetrieval)
@dynamic performingAutomaticRemoteUpdates, dataRetrievalBlocks, dataRetrievalInterval;

- (void) rescheduleAutomaticRemoteUpdates {

	[self.dataRetrievalTimer invalidate];
	self.dataRetrievalTimer = nil;

	self.dataRetrievalTimer = [NSTimer scheduledTimerWithTimeInterval:self.dataRetrievalInterval target:self selector:@selector(handleDataRetrievalTimerDidFire:) userInfo:nil repeats:NO];

}

- (void) performAutomaticRemoteUpdatesNow {

	[self.dataRetrievalTimer fire];
	[self.dataRetrievalTimer invalidate];
	[self rescheduleAutomaticRemoteUpdates];

}

- (void) handleDataRetrievalTimerDidFire:(NSTimer *)timer {

	[self.dataRetrievalBlocks irExecuteAllObjectsAsBlocks];
	[self rescheduleAutomaticRemoteUpdates];

}

- (void) beginPostponingDataRetrievalTimerFiring {

	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self performSelector:_cmd];
		});
		return;
	}
	
	[self willChangeValueForKey:@"isPostponingDataRetrievalTimerFiring"];
	self.dataRetrievalTimerPostponingCount = self.dataRetrievalTimerPostponingCount + 1;
	[self didChangeValueForKey:@"isPostponingDataRetrievalTimerFiring"];
	
	if (self.dataRetrievalTimerPostponingCount == 1) {
		[self.dataRetrievalTimer invalidate];
		self.dataRetrievalTimer = nil;
	}

}

- (void) endPostponingDataRetrievalTimerFiring {
	
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self performSelector:_cmd];
		});
		return;
	}

	NSParameterAssert(self.dataRetrievalTimerPostponingCount);
	[self willChangeValueForKey:@"isPostponingDataRetrievalTimerFiring"];
	self.dataRetrievalTimerPostponingCount = self.dataRetrievalTimerPostponingCount - 1;
	[self didChangeValueForKey:@"isPostponingDataRetrievalTimerFiring"];
	
	if (!self.dataRetrievalTimerPostponingCount) {
		[self rescheduleAutomaticRemoteUpdates];
	}

}

- (BOOL) isPostponingDataRetrievalTimerFiring {

	return !!(self.dataRetrievalTimerPostponingCount);

}

- (void) beginPerformingAutomaticRemoteUpdates {

	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self performSelector:_cmd];
		});
		return;
	}
	
	[self willChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];
	self.automaticRemoteUpdatesPerformingCount = self.automaticRemoteUpdatesPerformingCount + 1;
	[self didChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];

}

- (void) endPerformingAutomaticRemoteUpdates {

	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self performSelector:_cmd];
		});
		return;
	}
	
	NSParameterAssert(self.automaticRemoteUpdatesPerformingCount);
	
	[self willChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];
	self.automaticRemoteUpdatesPerformingCount = self.automaticRemoteUpdatesPerformingCount - 1;
	[self didChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];
	
}

- (BOOL) isPerformingAutomaticRemoteUpdates {

	return !!(self.automaticRemoteUpdatesPerformingCount);

}

- (NSArray *) defaultDataRetrievalBlocks {

	__block __typeof__(self) nrSelf = self;

	return [NSArray arrayWithObjects:
	
		[[ ^ {
		
			if (!nrSelf.userToken || !nrSelf.apiKey || !nrSelf.primaryGroupIdentifier)
				return;
				
			[AppDelegate() beginNetworkActivity];

			[nrSelf beginPerformingAutomaticRemoteUpdates];		
			[nrSelf beginPostponingDataRetrievalTimerFiring];
			
			[[WADataStore defaultStore] updateArticlesOnSuccess:^{

				[nrSelf endPerformingAutomaticRemoteUpdates];		
				[nrSelf endPostponingDataRetrievalTimerFiring];

				[AppDelegate() endNetworkActivity];
				
			} onFailure: ^ (NSError *error) {
			
				[nrSelf endPerformingAutomaticRemoteUpdates];		
				[nrSelf endPostponingDataRetrievalTimerFiring];
				
				[AppDelegate() endNetworkActivity];
				
			}];
		
		} copy] autorelease],
    
    [self defaultScheduledMonitoredHostsUpdatingBlock],
	
	nil];

}

- (void) addRepeatingDataRetrievalBlock:(void(^)(void))aBlock {

	[[self mutableArrayValueForKey:@"dataRetrievalBlocks"] irEnqueueBlock:aBlock];

}

- (void) addRepeatingDataRetrievalBlocks:(NSArray *)blocks{

	for (void(^aBlock)(void) in blocks)
		[self addRepeatingDataRetrievalBlock:aBlock];

}

@end


@implementation WARemoteInterface (ScheduledDataRetrieval_Private)
@dynamic performingAutomaticRemoteUpdates;

- (void) setDataRetrievalInterval:(NSTimeInterval)newDataRetrievalInterval {
	if (self.dataRetrievalInterval != newDataRetrievalInterval)
		objc_setAssociatedObject(self, &@selector(dataRetrievalInterval), [NSNumber numberWithDouble:newDataRetrievalInterval], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval) dataRetrievalInterval {
	NSNumber *value = objc_getAssociatedObject(self, &@selector(dataRetrievalInterval));
	return value ? [value doubleValue] : 30;
}

- (void) setDataRetrievalBlocks:(NSArray *)newDataRetrievalBlocks {
	if (self.dataRetrievalBlocks != newDataRetrievalBlocks)
		objc_setAssociatedObject(self, &@selector(dataRetrievalBlocks), newDataRetrievalBlocks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray *) dataRetrievalBlocks {
	NSArray *value = objc_getAssociatedObject(self, &@selector(dataRetrievalBlocks));
	if (!value) {
		value = [NSArray array];
		objc_setAssociatedObject(self, &@selector(dataRetrievalBlocks), value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return value;
}

- (void) setDataRetrievalTimer:(NSTimer *)newDataRetrievalTimer {
	if (self.dataRetrievalTimer != newDataRetrievalTimer)
		objc_setAssociatedObject(self, &@selector(dataRetrievalTimer), newDataRetrievalTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimer *) dataRetrievalTimer {
	return objc_getAssociatedObject(self, &@selector(dataRetrievalTimer));
}

- (void) setDataRetrievalTimerPostponingCount:(int)newDataRetrievalTimerPostponingCount {
	if (self.dataRetrievalTimerPostponingCount != newDataRetrievalTimerPostponingCount)
		objc_setAssociatedObject(self, &@selector(dataRetrievalTimerPostponingCount), [NSNumber numberWithInt:newDataRetrievalTimerPostponingCount], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (int) dataRetrievalTimerPostponingCount {
	NSNumber *value = objc_getAssociatedObject(self, &@selector(dataRetrievalTimerPostponingCount));
	return value ? [value intValue] : 0;
}

- (void) setAutomaticRemoteUpdatesPerformingCount:(int)newAutomaticRemoteUpdatesPerformingCount {
	if (self.automaticRemoteUpdatesPerformingCount != newAutomaticRemoteUpdatesPerformingCount)
		objc_setAssociatedObject(self, &@selector(automaticRemoteUpdatesPerformingCount), [NSNumber numberWithInt:newAutomaticRemoteUpdatesPerformingCount], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (int) automaticRemoteUpdatesPerformingCount {
	NSNumber *value = objc_getAssociatedObject(self, &@selector(automaticRemoteUpdatesPerformingCount));
	return value ? [value intValue] : 0;
}

@end
