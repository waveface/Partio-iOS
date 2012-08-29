//
//  WARemoteInterface+Reachability.m
//  wammer
//
//  Created by Evadne Wu on 11/25/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <objc/runtime.h>

#import "WARemoteInterface+Reachability.h"
#import "WAReachabilityDetector.h"

#import "Foundation+IRAdditions.h"

#import "WADefines.h"
#import "WAAppDelegate.h"

#import "WARemoteInterfaceContext.h"

#import "WARemoteInterface+WebSocket.h"
#import "WARemoteInterface+Notification.h"


@interface WARemoteInterface (Reachability_Private) <WAReachabilityDetectorDelegate>
NSURL *refiningStationLocation(NSString *stationUrlString, NSURL *baseUrl) ;
@property (nonatomic, readonly, retain) NSMutableDictionary *monitoredHostsToReachabilityDetectors;

@end


static NSString * const kAvailableHosts = @"-[WARemoteInterface(Reachability) availableHosts]";
static NSString * const kNetworkState = @"-[WARemoteInterface(Reachability) networkState]";


@implementation WARemoteInterface (Reachability)

+ (void) load {

	__weak NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	
	__block id appLoaded = [center addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
		
		[center removeObserver:appLoaded];
		objc_setAssociatedObject([WARemoteInterface class], &UIApplicationDidFinishLaunchingNotification, nil, OBJC_ASSOCIATION_ASSIGN);
		
		__block id baseURLChanged = [center addObserverForName:kWARemoteInterfaceContextDidChangeBaseURLNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
			
			NSURL *oldURL = [[note userInfo] objectForKey:kWARemoteInterfaceContextOldBaseURL];
			NSURL *newURL = [[note userInfo] objectForKey:kWARemoteInterfaceContextNewBaseURL];
			
			WARemoteInterface *ri = [WARemoteInterface sharedInterface];
			
			NSArray *monitoredHosts = ri.monitoredHosts;
			NSMutableArray *updatedHosts = [monitoredHosts mutableCopy];
			
			for (NSURL *anURL in ri.monitoredHosts)
				if ([anURL isEqual:oldURL] || [anURL isEqual:newURL])
					[updatedHosts removeObject:anURL];

			[updatedHosts insertObject:newURL atIndex:0];
			
			ri.monitoredHosts = updatedHosts;
			
		}];
		
		objc_setAssociatedObject([WARemoteInterface class], &kWARemoteInterfaceContextDidChangeBaseURLNotification, baseURLChanged, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
				
	}];

	objc_setAssociatedObject([WARemoteInterface class], &UIApplicationDidFinishLaunchingNotification, appLoaded, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

- (NSArray *) monitoredHosts {

	return objc_getAssociatedObject(self, &kAvailableHosts);

}

- (void) setMonitoredHosts:(NSArray *)newAvailableHosts {

  if ([self.monitoredHosts isEqualToArray:newAvailableHosts])
    return;

	objc_setAssociatedObject(self, &kAvailableHosts, newAvailableHosts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
  [(NSDictionary *)[self.monitoredHostsToReachabilityDetectors copy] enumerateKeysAndObjectsUsingBlock: ^ (NSURL *anURL, WAReachabilityDetector *reachabilityDetector, BOOL *stop) {
  
    if (![newAvailableHosts containsObject:anURL])
      [self.monitoredHostsToReachabilityDetectors removeObjectForKey:anURL];
    
  }];
  
  [newAvailableHosts enumerateObjectsUsingBlock: ^ (NSURL *aHostURL, NSUInteger idx, BOOL *stop) {
  
    if (![[self.monitoredHostsToReachabilityDetectors allKeys] containsObject:aHostURL]) {
      
      WAReachabilityDetector *detector = [WAReachabilityDetector detectorForURL:aHostURL];
      detector.delegate = self;
      
      [self.monitoredHostsToReachabilityDetectors setObject:detector forKey:aHostURL];
      
    }
    
  }];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kWARemoteInterfaceReachableHostsDidChangeNotification object:self userInfo:nil];
  
}

- (BOOL) canHost:(NSURL *)aHost handleRequestNamed:(NSString *)aRequestName {

  NSString *cloudHost = [self.engine.context.baseURL host];
  BOOL incomingURLIsCloud = [[aHost host] isEqualToString:cloudHost];

  if ([aRequestName hasPrefix:@"reachability"])
    return incomingURLIsCloud;
    
  if ([aRequestName hasPrefix:@"auth/"])
    return incomingURLIsCloud;
  
  if ([aRequestName hasPrefix:@"stations/"])
    return incomingURLIsCloud;
	
  if ([aRequestName hasPrefix:@"users/"])
    return incomingURLIsCloud;
  
  if ([aRequestName hasPrefix:@"groups/"])
    return incomingURLIsCloud;
    
  WAReachabilityDetector *detectorForHost = [self.monitoredHostsToReachabilityDetectors objectForKey:aHost];
  
  if (!detectorForHost)
    if ([[aHost host] isEqualToString:cloudHost])
      return YES; //  heh
  
  return (detectorForHost.state == WAReachabilityStateAvailable);
  
}

- (NSURL *) bestHostForRequestNamed:(NSString *)aRequestName {

  //  If nothing is monitored, use the base URL
  
  if (![self.monitoredHosts count])
    return self.engine.context.baseURL;
  
  NSArray *usableHosts = [[self.monitoredHosts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (NSURL *aHost, NSDictionary *bindings) {
    
    return [self canHost:aHost handleRequestNamed:aRequestName];
    
  }]] sortedArrayUsingComparator: (NSComparator) ^ (NSURL *lhsHost, NSURL *rhsHost) {
    
    WAReachabilityDetector *lhsReachabilityDetector = [self.monitoredHostsToReachabilityDetectors objectForKey:lhsHost];
    WAReachabilityDetector *rhsReachabilityDetector = [self.monitoredHostsToReachabilityDetectors objectForKey:rhsHost];
    
    if (!lhsReachabilityDetector && !rhsReachabilityDetector)
      return NSOrderedSame;
    else if (lhsReachabilityDetector && !rhsReachabilityDetector)
      return NSOrderedAscending;
    else if (!lhsReachabilityDetector && rhsReachabilityDetector)
      return NSOrderedDescending;
    
    WAReachabilityState lhsState = lhsReachabilityDetector.state;
    WAReachabilityState rhsState = rhsReachabilityDetector.state;
    
    BOOL lhsAppLayerAlive = (lhsState == WAReachabilityStateAvailable);
    BOOL rhsAppLayerAlive = (rhsState == WAReachabilityStateAvailable);
    
    if (!lhsAppLayerAlive && !rhsAppLayerAlive)
      return NSOrderedSame;
    else if (lhsAppLayerAlive && !rhsAppLayerAlive)
      return NSOrderedAscending;
    else if (!lhsAppLayerAlive && rhsAppLayerAlive)
      return NSOrderedDescending;
    
    SCNetworkReachabilityFlags lhsFlags = lhsReachabilityDetector.networkStateFlags;
    SCNetworkReachabilityFlags rhsFlags = rhsReachabilityDetector.networkStateFlags;
    
    BOOL lhsReachable = WASCNetworkReachable(lhsFlags);
    BOOL rhsReachable = WASCNetworkReachable(rhsFlags);
    
    if (!lhsReachable && !rhsReachable)
      return NSOrderedSame;
    else if (lhsReachable && !rhsReachable)
      return NSOrderedAscending;
    else if (!lhsReachable && rhsReachable)
      return NSOrderedDescending;
    
    BOOL lhsIsDirect = WASCNetworkReachableDirectly(lhsFlags);
    BOOL rhsIsDirect = WASCNetworkReachableDirectly(rhsFlags);
    
    if (lhsIsDirect && !rhsIsDirect)
      return NSOrderedAscending;
    else if (!lhsIsDirect && rhsIsDirect)
      return NSOrderedDescending;
    
    BOOL lhsOnWiFi = WASCNetworkReachableViaWifi(lhsFlags);
    BOOL rhsOnWiFi = WASCNetworkReachableViaWifi(rhsFlags);
    
    if (lhsOnWiFi && !rhsOnWiFi)
      return NSOrderedAscending;
    else if (!lhsOnWiFi && rhsOnWiFi)
      return NSOrderedDescending;
    
    BOOL lhsOnWWAN = WASCNetworkReachableViaWWAN(lhsFlags);
    BOOL rhsOnWWAN = WASCNetworkReachableViaWWAN(rhsFlags);
    
    if (lhsOnWWAN && !rhsOnWWAN)
      return NSOrderedAscending;
    else if (!lhsOnWWAN && rhsOnWWAN)
      return NSOrderedDescending;
    
    return NSOrderedSame;
    
  }];
  
  if ([usableHosts count])
    return [usableHosts objectAtIndex:0];
  
  return self.engine.context.baseURL;

}

NSURL *refiningStationLocation(NSString *stationUrlString, NSURL *baseUrl) {
	NSURL *givenURL = [NSURL URLWithString:stationUrlString];
	if (!givenURL)
		return (id)nil;
	
	if (![givenURL host])
		return (id)nil;
	
	NSString *baseURLString = [[NSArray arrayWithObjects:
															
															[givenURL scheme] ? [[givenURL scheme] stringByAppendingString:@"://"] :
															[baseUrl scheme] ? [[baseUrl scheme] stringByAppendingString:@"://"] : @"",
															[baseUrl host] ? [givenURL host] : @"",
															[givenURL port] ? [@":" stringByAppendingString:[[givenURL port] stringValue]] :
															[baseUrl port] ? [@":" stringByAppendingString:[[baseUrl port] stringValue]] : @"",
															[baseUrl path] ? [baseUrl path] : @"",
															@"/", //  path needs trailing slash
															
															//	[givenURL query] ? [@"?" stringByAppendingString:[givenURL query]] : @"",
															//	[givenURL fragment] ? [@"#" stringByAppendingString:[givenURL fragment]] : @"",
															
															nil] componentsJoinedByString:@""];
	
	//  only take the location (host) + port, nothing else
	
	return (id)[NSURL URLWithString:baseURLString];

	
}

- (void(^)(void)) defaultScheduledMonitoredHostsUpdatingBlock {

  __weak WARemoteInterface *wSelf = self;

  return [^ {
  
    if (!wSelf.userToken)
      return;
		
    [wSelf beginPostponingDataRetrievalTimerFiring];
    //[((WAAppDelegate *)[UIApplication sharedApplication].delegate) beginNetworkActivity];
  
    [wSelf retrieveAssociatedStationsOfCurrentUserOnSuccess:^(NSArray *stationReps) {

      dispatch_async(dispatch_get_main_queue(), ^ {

				NSArray *wsStations = [NSArray arrayWithArray:[stationReps irMap: ^(NSDictionary *aStationRep, NSUInteger index, BOOL *stop) {
					NSString *wsStationURLString = [aStationRep valueForKey:@"ws_location"];
					if (!wsStationURLString)
						return (id)nil;

					NSURL *wsURL = [NSURL URLWithString:wsStationURLString];
					
					NSURL *stationURL = refiningStationLocation([aStationRep valueForKey:@"location"], wSelf.engine.context.baseURL);
					
					return (id)[[NSDictionary alloc] initWithObjectsAndKeys:stationURL, @"location", wsURL, @"ws_location", nil];

				}]];
					
				if ([wsStations count] > 0) {
					NSURL *wsURL = [(NSDictionary*)[wsStations objectAtIndex:0] objectForKey:@"ws_location"];
					NSURL *stURL = [(NSDictionary*)[wsStations objectAtIndex:0] objectForKey:@"location"];
					
					[[WARemoteInterface sharedInterface] stopAutomaticRemoteUpdates];

					[[WARemoteInterface sharedInterface] openWebSocketConnectionForUrl: wsURL onSucces:^{

						[[WARemoteInterface sharedInterface] subscribeNotification];
						// We only scan the reachability detector for cloud and the first station that supports websocket
						wSelf.monitoredHosts = [NSArray arrayWithObjects:wSelf.engine.context.baseURL, stURL, nil];
						
					} onFailure:^(NSError *error) {
						
						wSelf.monitoredHosts = [NSArray arrayWithObject:wSelf.engine.context.baseURL];
						[[WARemoteInterface sharedInterface] performAutomaticRemoteUpdatesNow];

					}];
					

				} else {

					wSelf.monitoredHosts = [[NSArray arrayWithObject:wSelf.engine.context.baseURL] arrayByAddingObjectsFromArray:[stationReps irMap: ^ (NSDictionary *aStationRep, NSUInteger index, BOOL *stop) {
        
						NSString *stationURLString = [aStationRep valueForKeyPath:@"location"];
						if (!stationURLString)
							return (id)nil;
					          				
						return (id)refiningStationLocation(stationURLString, wSelf.engine.context.baseURL);
					}]];
					
				}
        
        [wSelf endPostponingDataRetrievalTimerFiring];
				
				//[AppDelegate() endNetworkActivity];
      
      });
    
    } onFailure:^(NSError *error) {
    
      dispatch_async(dispatch_get_main_queue(), ^ {
      
				// for network unavailable case while entering app
				if (!wSelf.monitoredHosts) {
					wSelf.monitoredHosts = [NSArray arrayWithObject:wSelf.engine.context.baseURL];
				}

        [wSelf endPostponingDataRetrievalTimerFiring];

        //[AppDelegate() endNetworkActivity];
      
      });
        
    }];
  
  } copy];

}

- (IRWebAPIRequestContextTransformer) defaultHostSwizzlingTransformer {

  __weak WARemoteInterface *wSelf = self;

	return [^ (IRWebAPIRequestContext *context) {
	
    NSString *originalMethodName = context.engineMethod;
    NSURL *originalURL = context.baseURL;

    if ([originalMethodName hasPrefix:@"reachability"])
      return context;

    if ([originalMethodName hasPrefix:@"loadedResource"]) {
			
			if (![[originalURL host] isEqualToString:[[WARemoteInterface sharedInterface].engine.context.baseURL host]])
				return context;

			//	if ([[inOriginalContext objectForKey:@"target"] isEqual:@"image"])
			//		return inOriginalContext;
      
    }
    
    NSURL *bestHostURL = [wSelf bestHostForRequestNamed:originalMethodName];
    NSParameterAssert(bestHostURL);
    
    NSURL *swizzledURL = [NSURL URLWithString:[[NSArray arrayWithObjects:

      [bestHostURL scheme] ? [[bestHostURL scheme] stringByAppendingString:@"://"] :
        [originalURL scheme] ? [[originalURL scheme] stringByAppendingString:@"://"] : @"",
      
      [originalURL host] ? [bestHostURL host] : @"",
      
      [bestHostURL port] ? [@":" stringByAppendingString:[[bestHostURL port] stringValue]] : 
        [originalURL port] ? [@":" stringByAppendingString:[[originalURL port] stringValue]] : @"",
      
      [originalURL path] ? [originalURL path] : @"/",
      [originalURL query] ? [@"?" stringByAppendingString:[originalURL query]] : @"",
      [originalURL fragment] ? [@"#" stringByAppendingString:[originalURL fragment]] : @"",
    
    nil] componentsJoinedByString:@""]];
    
		context.baseURL = swizzledURL;
		
		return context;
	
	} copy];

}

- (WAReachabilityState) reachabilityStateForHost:(NSURL *)aBaseURL {

  WAReachabilityDetector *detector = [self reachabilityDetectorForHost:aBaseURL];
  return detector ? detector.state : WAReachabilityStateUnknown;

}

- (WAReachabilityDetector *) reachabilityDetectorForHost:(NSURL *)aBaseURL {

  WAReachabilityDetector *detector = [self.monitoredHostsToReachabilityDetectors objectForKey:aBaseURL];
  return detector;

}

- (WANetworkState) networkState {

  NSURL *cloudHost = self.engine.context.baseURL;
	BOOL hasStationAvailable = NO, hasCloudAvailable = NO;
	
	for (NSURL *hostURL in self.monitoredHosts) {
		switch ([self reachabilityStateForHost:hostURL]) {
			case WAReachabilityStateAvailable:
				if ([hostURL isEqual:cloudHost]) {
					hasCloudAvailable = YES;
				} else {
					hasStationAvailable = YES;
				}
				break;

			case WAReachabilityStateUnknown:
				// assume cloud is reachable by default
				if ([hostURL isEqual:cloudHost]) {
					hasCloudAvailable = YES;
				}
				break;
				
			default:
				break;
		}
	}
	
	// assume cloud is reachable before calling findMyStation
	if (!self.monitoredHosts) {
		hasCloudAvailable = YES;
	}

	BOOL answer = (hasCloudAvailable ? WACloudReachable : 0) | (hasStationAvailable ? WAStationReachable : 0);
	
	return answer;
  
}

@end





@implementation WARemoteInterface (Reachability_Private)

- (NSMutableDictionary *) monitoredHostsToReachabilityDetectors {

	NSMutableDictionary *returnedDictionary = objc_getAssociatedObject(self, _cmd);
	if (!returnedDictionary) {
		returnedDictionary = [NSMutableDictionary dictionary];
		objc_setAssociatedObject(self, _cmd, returnedDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	
	return returnedDictionary;

}

- (void) reachabilityDetectorDidUpdate:(WAReachabilityDetector *)aDetector {

	[self willChangeValueForKey:@"networkState"];

	[self didChangeValueForKey:@"networkState"];


}

@end