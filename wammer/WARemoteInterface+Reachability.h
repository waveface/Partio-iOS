//
//  WARemoteInterface+Reachability.h
//  wammer
//
//  Created by Evadne Wu on 11/25/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface.h"
#import "IRWebAPIKitDefines.h"
#import "WAReachabilityDetector.h"

#ifndef __WARemoteInterface_Reachability__
#define __WARemoteInterface_Reachability__

enum {
	
	WACloudReachable = 1 << 1,		//	The Cloud is reachable
	WAStationReachable = 1 << 2,	//	Any Station is reachable
	
	WAEndpointsUnreachable = 0		//	Nothing is reachable, Internet may be working or not
	
}; typedef NSUInteger WANetworkState;

#endif /* __WARemoteInterface_Reachability__ */


@class WAReachabilityDetector;
@interface WARemoteInterface (Reachability)

@property (nonatomic, readwrite, retain) NSArray *monitoredHosts;
@property (nonatomic, readonly, assign) WANetworkState networkState;

- (BOOL) canHost:(NSURL *)aHost handleRequestNamed:(NSString *)aRequestName;
- (NSURL *) bestHostForRequestNamed:(NSString *)aRequestName;

- (void(^)(void)) defaultScheduledMonitoredHostsUpdatingBlock;
- (IRWebAPIRequestContextTransformer) defaultHostSwizzlingTransformer;

- (WAReachabilityState) reachabilityStateForHost:(NSURL *)aBaseURL;
- (WAReachabilityDetector *) reachabilityDetectorForHost:(NSURL *)aBaseURL;

@end
