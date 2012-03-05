//
//  WAFile+WARemoteInterfaceEntitySyncing.h
//  wammer
//
//  Created by Evadne Wu on 11/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAFile.h"
#import "WARemoteInterfaceEntitySyncing.h"


extern NSString * kWAFileEntitySyncingErrorDomain;

extern NSString * const kWAFileSyncStrategy;
typedef NSString * WAFileSyncStrategy;

extern NSString * const kWAFileSyncDefaultStrategy;	//	kWAFileSyncAdaptiveQualityStrategy
extern NSString * const kWAFileSyncAdaptiveQualityStrategy;
//	medium, or origin + medium
//	Depending on -[WARemoteInterface areExpensiveOperationsAllowed]
//	Should be the best strategy to use when invoked by user interaction

extern NSString * const kWAFileSyncReducedQualityStrategy;
//	medium only
//	Useful for cases where speed is key.  Or when the network connection is bad.

extern NSString * const kWAFileSyncFullQualityStrategy;
//	origin + medium
//	This is best used with a background worker since it takes up most time and bandwidth.
//	Not recommended to be used on a carrier-provided connection (might be a capped 3G)


@interface WAFile (WARemoteInterfaceEntitySyncing) <WARemoteInterfaceEntitySyncing>

@end
