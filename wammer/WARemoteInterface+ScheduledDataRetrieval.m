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

	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	[self.dataRetrievalTimer fire];
	[self.dataRetrievalTimer invalidate];
	[self rescheduleAutomaticRemoteUpdates];

}

- (void) handleDataRetrievalTimerDidFire:(NSTimer *)timer {

	if ([self isPostponingDataRetrievalTimerFiring]) {
		NSLog(@"%s: is postponing timer firing, should NOT fire", __PRETTY_FUNCTION__);
		return;
	}

	NSLog(@"%s %@", __PRETTY_FUNCTION__, timer);

	[self.dataRetrievalBlocks irExecuteAllObjectsAsBlocks];
	[self rescheduleAutomaticRemoteUpdates];

}

- (void) beginPostponingDataRetrievalTimerFiring {

	NSLog(@"%s", __PRETTY_FUNCTION__);

	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self beginPostponingDataRetrievalTimerFiring];
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
	
	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self endPostponingDataRetrievalTimerFiring];
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

	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	return !!(self.dataRetrievalTimerPostponingCount);

}

- (void) beginPerformingAutomaticRemoteUpdates {

	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self beginPerformingAutomaticRemoteUpdates];
		});
		return;
	}
	
	[self willChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];
	self.automaticRemoteUpdatesPerformingCount = self.automaticRemoteUpdatesPerformingCount + 1;
	[self didChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];

}

- (void) endPerformingAutomaticRemoteUpdates {

	NSLog(@"%s", __PRETTY_FUNCTION__);
	
	if (![NSThread isMainThread]) {
		dispatch_async(dispatch_get_main_queue(), ^ {
			[self endPerformingAutomaticRemoteUpdates];
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

	__weak WARemoteInterface *wSelf = self;

	return [NSArray arrayWithObjects:
	
		[^ {
		
			if (!wSelf.userToken || !wSelf.apiKey || !wSelf.primaryGroupIdentifier)
				return;
				
			[AppDelegate() beginNetworkActivity];

			[wSelf beginPerformingAutomaticRemoteUpdates];		
			[wSelf beginPostponingDataRetrievalTimerFiring];
			
			[[WADataStore defaultStore] updateArticlesOnSuccess:^{

				[wSelf endPerformingAutomaticRemoteUpdates];		
				[wSelf endPostponingDataRetrievalTimerFiring];

				[AppDelegate() endNetworkActivity];
				
			} onFailure: ^ (NSError *error) {
			
				[wSelf endPerformingAutomaticRemoteUpdates];		
				[wSelf endPostponingDataRetrievalTimerFiring];
				
				[AppDelegate() endNetworkActivity];
				
			}];
		
		} copy],
		
		[^ {
		
			if (!wSelf.userToken || !wSelf.apiKey || !wSelf.primaryGroupIdentifier)
				return;
				
			[AppDelegate() beginNetworkActivity];

			[wSelf beginPerformingAutomaticRemoteUpdates];		
			[wSelf beginPostponingDataRetrievalTimerFiring];
			
			[[WADataStore defaultStore] updateCurrentUserOnSuccess:^{

				[wSelf endPerformingAutomaticRemoteUpdates];		
				[wSelf endPostponingDataRetrievalTimerFiring];

				[AppDelegate() endNetworkActivity];
				
			} onFailure: ^ {
			
				[wSelf endPerformingAutomaticRemoteUpdates];		
				[wSelf endPostponingDataRetrievalTimerFiring];
				
				[AppDelegate() endNetworkActivity];
				
			}];
		
		} copy],
    
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

static NSString * const kDataRetrievalInterval = @"dataRetrievalInterval";
static NSString * const kDataRetrievalBlocks = @"dataRetrievalBlocks";
static NSString * const kDataRetrievalTimer = @"dataRetrievalTimer";
static NSString * const kDataRetrievalTimerPostponingCount = @"dataRetrievalTimerPostponingCount";
static NSString * const kDataRetrievalTimerPerformingCount = @"dataRetrievalTimerPerformingCount";

- (void) setDataRetrievalInterval:(NSTimeInterval)newDataRetrievalInterval {

	objc_setAssociatedObject(self, &kDataRetrievalInterval, [NSNumber numberWithDouble:newDataRetrievalInterval], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
}

- (NSTimeInterval) dataRetrievalInterval {
	
	NSNumber *value = objc_getAssociatedObject(self, &kDataRetrievalInterval);
	return value ? [value doubleValue] : 30;
	
}

- (void) setDataRetrievalBlocks:(NSArray *)newDataRetrievalBlocks {

	objc_setAssociatedObject(self, &kDataRetrievalBlocks, newDataRetrievalBlocks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
}

- (NSArray *) dataRetrievalBlocks {
	
	NSArray *value = objc_getAssociatedObject(self, &kDataRetrievalBlocks);
	if (!value) {
		
		value = [NSArray array];
		objc_setAssociatedObject(self, &kDataRetrievalBlocks, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		
	}
	
	return value;
}

- (void) setDataRetrievalTimer:(NSTimer *)newDataRetrievalTimer {

	objc_setAssociatedObject(self, &kDataRetrievalTimer, newDataRetrievalTimer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
}

- (NSTimer *) dataRetrievalTimer {
	
	return objc_getAssociatedObject(self, &kDataRetrievalTimer);
	
}

- (void) setDataRetrievalTimerPostponingCount:(int)newDataRetrievalTimerPostponingCount {
	
	objc_setAssociatedObject(self, &kDataRetrievalTimerPostponingCount, [NSNumber numberWithInt:newDataRetrievalTimerPostponingCount], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
}

- (int) dataRetrievalTimerPostponingCount {
	
	NSNumber *value = objc_getAssociatedObject(self, &kDataRetrievalTimerPostponingCount);
	return value ? [value intValue] : 0;
	
}

- (void) setAutomaticRemoteUpdatesPerformingCount:(int)newAutomaticRemoteUpdatesPerformingCount {

	objc_setAssociatedObject(self, &kDataRetrievalTimerPerformingCount, [NSNumber numberWithInt:newAutomaticRemoteUpdatesPerformingCount], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	
}

- (int) automaticRemoteUpdatesPerformingCount {
	
	NSNumber *value = objc_getAssociatedObject(self, &kDataRetrievalTimerPerformingCount);
	return value ? [value intValue] : 0;
	
}

@end
