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

@class WAReachabilityDetector;
@interface WARemoteInterface (Reachability)

@property (nonatomic, readwrite, retain) NSArray *monitoredHosts;

- (BOOL) canHost:(NSURL *)aHost handleRequestNamed:(NSString *)aRequestName;
- (NSURL *) bestHostForRequestNamed:(NSString *)aRequestName;

- (void(^)(void)) defaultScheduledMonitoredHostsUpdatingBlock;
- (IRWebAPIRequestContextTransformer) defaultHostSwizzlingTransformer;

- (WAReachabilityState) reachabilityStateForHost:(NSURL *)aBaseURL;
- (WAReachabilityDetector *) reachabilityDetectorForHost:(NSURL *)aBaseURL;

@end
