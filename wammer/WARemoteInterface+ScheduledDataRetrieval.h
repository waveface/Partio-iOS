//
//  WARemoteInterface+ScheduledDataRetrieval.h
//  wammer
//
//  Created by Evadne Wu on 11/4/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"

@interface WARemoteInterface (ScheduledDataRetrieval)

//	The data retrieval is usually scheduled every 30 seconds, described by the dataRetrievalInterval property.  If any remote operation began, and it will eventually load data that will also be loaded by the data retrieval blocks, call -rescheduleNextAutomaticDataRetrieval frequently to block automatic data retrieval.  Blocking auto data retrieval during manual / other implicit remote data loading avoids wasting time working on local store merging.

- (void) beginPostponingDataRetrievalTimerFiring;
- (void) endPostponingDataRetrievalTimerFiring;
- (BOOL) isPostponingDataRetrievalTimerFiring;

- (void) rescheduleAutomaticRemoteUpdates;
- (void) performAutomaticRemoteUpdatesNow;	// Also reschedules, great for manual refreshing

- (void) beginPerformingAutomaticRemoteUpdates;
- (void) endPerformingAutomaticRemoteUpdates;
- (BOOL) isPerformingAutomaticRemoteUpdates;

@property (nonatomic, readonly, assign, getter=isPerformingAutomaticRemoteUpdates) BOOL performingAutomaticRemoteUpdates;	//	KVO-able for manual refreshing buttons
@property (nonatomic, readwrite, assign) NSTimeInterval dataRetrievalInterval;
@property (nonatomic, readonly, retain) NSArray *dataRetrievalBlocks;

- (NSArray *) defaultDataRetrievalBlocks;
- (void) addRepeatingDataRetrievalBlock:(void(^)(void))aBlock;
- (void) addRepeatingDataRetrievalBlocks:(NSArray *)blocks;

@end
