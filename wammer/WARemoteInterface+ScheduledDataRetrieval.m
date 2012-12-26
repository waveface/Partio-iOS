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
@property (nonatomic, readwrite, assign) BOOL dataRetrievalTimerEnabled;

@end


@implementation WARemoteInterface (ScheduledDataRetrieval)
@dynamic performingAutomaticRemoteUpdates, dataRetrievalBlocks, dataRetrievalInterval;

- (void) rescheduleAutomaticRemoteUpdates {
  
  if (self.dataRetrievalTimerEnabled) {
    [self.dataRetrievalTimer invalidate];
    self.dataRetrievalTimer = nil;
    
    self.dataRetrievalTimer = [NSTimer scheduledTimerWithTimeInterval:self.dataRetrievalInterval target:self selector:@selector(handleDataRetrievalTimerDidFire:) userInfo:nil repeats:NO];
  }
  
}

- (void) stopAutomaticRemoteUpdates {
  if (self.dataRetrievalTimerEnabled) {
    self.dataRetrievalTimerEnabled = NO;
    [self.dataRetrievalTimer invalidate];
  }
}

- (void) enableAutomaticRemoteUpdatesTimer {
  self.dataRetrievalTimerEnabled = YES;
  [self rescheduleAutomaticRemoteUpdates];
}

- (void) performAutomaticRemoteUpdatesNow {
  
  [self willChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];
  
  if (!self.dataRetrievalTimer.isValid) {
    // Timer has already been stopped, reschedule it and fire again
    self.dataRetrievalTimer = nil;
    self.dataRetrievalTimer = [NSTimer scheduledTimerWithTimeInterval:self.dataRetrievalInterval target:self selector:@selector(handleDataRetrievalTimerDidFire:) userInfo:nil repeats:NO];
  }
  
  [self.dataRetrievalTimer fire];
  [self.dataRetrievalTimer invalidate];
  
  [self rescheduleAutomaticRemoteUpdates];
  
  [self didChangeValueForKey:@"isPerformingAutomaticRemoteUpdates"];
  
}

- (void) handleDataRetrievalTimerDidFire:(NSTimer *)timer {
  
  if ([self isPostponingDataRetrievalTimerFiring])
    return;
  
  [self.dataRetrievalBlocks irExecuteAllObjectsAsBlocks];
  [self rescheduleAutomaticRemoteUpdates];
  
}

- (void) beginPostponingDataRetrievalTimerFiring {
  
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
  
  return !!(self.dataRetrievalTimerPostponingCount);
  
}

- (void) beginPerformingAutomaticRemoteUpdates {
  
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

+ (NSSet *) keyPathsForValuesAffectingPerformingAutomaticRemoteUpdates {
  
  return [NSSet setWithObjects:
	
	@"automaticRemoteUpdatesPerformingCount",
	
	nil];
  
}

- (BOOL) isPerformingAutomaticRemoteUpdates {
  
  return !!(self.dataRetrievalTimer) && !!(self.automaticRemoteUpdatesPerformingCount);
  
}

- (NSArray *) defaultDataRetrievalBlocks {
  
  __weak WARemoteInterface *wSelf = self;
  
  return @[[^ {
    
    if (!wSelf.userToken || !wSelf.apiKey || !wSelf.primaryGroupIdentifier)
      return;
    
    [wSelf beginPerformingAutomaticRemoteUpdates];
    [wSelf beginPostponingDataRetrievalTimerFiring];
    
    [[WADataStore defaultStore] updateCurrentUserOnSuccess:^{
      
      [wSelf endPerformingAutomaticRemoteUpdates];
      [wSelf endPostponingDataRetrievalTimerFiring];
      
    } onFailure: ^ {
      
      [wSelf endPerformingAutomaticRemoteUpdates];
      [wSelf endPostponingDataRetrievalTimerFiring];
      
    }];
    
  } copy],
  
  [self defaultScheduledMonitoredHostsUpdatingBlock],
  
  [^ {
    
    if (!wSelf.userToken || !wSelf.apiKey || !wSelf.primaryGroupIdentifier)
      return;
    
    [wSelf beginPerformingAutomaticRemoteUpdates];
    [wSelf beginPostponingDataRetrievalTimerFiring];
    
    [[WADataStore defaultStore] updateArticlesOnSuccess:^{
      
      [[WADataStore defaultStore] updateAttachmentsMetaOnSuccess:^{
        
        [wSelf endPerformingAutomaticRemoteUpdates];
        [wSelf endPostponingDataRetrievalTimerFiring];
        
      } onFailure:^(NSError *error) {
        
        [wSelf endPerformingAutomaticRemoteUpdates];
        [wSelf endPostponingDataRetrievalTimerFiring];
        
      }];
      
    } onFailure: ^ (NSError *error) {
      
      [wSelf endPerformingAutomaticRemoteUpdates];
      [wSelf endPostponingDataRetrievalTimerFiring];
      
    }];
    
  } copy],
  
  [^ {
    
    if (!wSelf.userToken || !wSelf.apiKey || !wSelf.primaryGroupIdentifier)
      return;
    
    [wSelf beginPerformingAutomaticRemoteUpdates];
    [wSelf beginPostponingDataRetrievalTimerFiring];
    
    [[WADataStore defaultStore]
     updateCollectionsOnSuccess:^{
       [wSelf endPerformingAutomaticRemoteUpdates];
       [wSelf endPostponingDataRetrievalTimerFiring];
       
     } onFailure:^(NSError *error) {
       [wSelf endPerformingAutomaticRemoteUpdates];
       [wSelf endPostponingDataRetrievalTimerFiring];
       
     }];
    
  } copy]
  ];
  
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
static NSString * const kDataRetrievalTimerEnabled = @"dataRetrievalTimerEnabled";

- (void) setDataRetrievalInterval:(NSTimeInterval)newDataRetrievalInterval {
  
  objc_setAssociatedObject(self, &kDataRetrievalInterval, @(newDataRetrievalInterval), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
}

- (NSTimeInterval) dataRetrievalInterval {
  
  NSNumber *value = objc_getAssociatedObject(self, &kDataRetrievalInterval);
  return value ? [value doubleValue] : 30;
  
}

- (void) setDataRetrievalTimerEnabled:(BOOL)dataRetrievalTimerEnabled
{
  objc_setAssociatedObject(self, &kDataRetrievalTimerEnabled, @(dataRetrievalTimerEnabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL) dataRetrievalTimerEnabled
{
  NSNumber *ret = objc_getAssociatedObject(self, &kDataRetrievalTimerEnabled);
  return ret ? [ret boolValue] : NO;
}

- (void) setDataRetrievalBlocks:(NSArray *)newDataRetrievalBlocks {
  
  objc_setAssociatedObject(self, &kDataRetrievalBlocks, newDataRetrievalBlocks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
}

- (NSArray *) dataRetrievalBlocks {
  
  NSArray *value = objc_getAssociatedObject(self, &kDataRetrievalBlocks);
  if (!value) {
    
    value = @[];
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
  
  objc_setAssociatedObject(self, &kDataRetrievalTimerPostponingCount, @(newDataRetrievalTimerPostponingCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
}

- (int) dataRetrievalTimerPostponingCount {
  
  NSNumber *value = objc_getAssociatedObject(self, &kDataRetrievalTimerPostponingCount);
  return value ? [value intValue] : 0;
  
}

- (void) setAutomaticRemoteUpdatesPerformingCount:(int)newAutomaticRemoteUpdatesPerformingCount {
  
  objc_setAssociatedObject(self, &kDataRetrievalTimerPerformingCount, @(newAutomaticRemoteUpdatesPerformingCount), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
}

- (int) automaticRemoteUpdatesPerformingCount {
  
  NSNumber *value = objc_getAssociatedObject(self, &kDataRetrievalTimerPerformingCount);
  return value ? [value intValue] : 0;
  
}

@end
