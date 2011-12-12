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


@interface WARemoteInterface (Reachability_Private) <WAReachabilityDetectorDelegate>

@property (nonatomic, readonly, retain) NSMutableDictionary *monitoredHostsToReachabilityDetectors;

@end


@implementation WARemoteInterface (Reachability)

static NSString * const kWARemoteInterface_Reachability_availableHosts = @"WARemoteInterface)Reachability)-availableHosts";

- (NSArray *) monitoredHosts {

	return objc_getAssociatedObject(self, &kWARemoteInterface_Reachability_availableHosts);

}

- (void) setMonitoredHosts:(NSArray *)newAvailableHosts {

  if (self.monitoredHosts == newAvailableHosts)
    return;

	objc_setAssociatedObject(self, &kWARemoteInterface_Reachability_availableHosts, newAvailableHosts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
  [(NSDictionary *)[[self.monitoredHostsToReachabilityDetectors copy] autorelease] enumerateKeysAndObjectsUsingBlock: ^ (NSURL *anURL, WAReachabilityDetector *reachabilityDetector, BOOL *stop) {
  
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
  
  if ([aRequestName hasPrefix:@"auth/"])
    return incomingURLIsCloud;
  
  if ([aRequestName hasPrefix:@"reachability"])
    return incomingURLIsCloud;
    
  if ([aRequestName hasPrefix:@"stations"])
    return incomingURLIsCloud;
    
  if ([aRequestName hasPrefix:@"users/findMyStation"])
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
  
  NSArray *usableHosts = [[self.monitoredHosts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURL *aHost, NSDictionary *bindings) {
    
    return [self canHost:aHost handleRequestNamed:aRequestName];
    
  }]] sortedArrayUsingComparator: ^ (NSURL *lhsHost, NSURL *rhsHost) {
    
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

- (void(^)(void)) defaultScheduledMonitoredHostsUpdatingBlock {

  __block __typeof__(self) nrSelf = self;

  return [[ ^ {
  
    if (!nrSelf.userToken)
      return;
      
    [nrSelf beginPostponingDataRetrievalTimerFiring];
    [((WAAppDelegate *)[UIApplication sharedApplication].delegate) beginNetworkActivity];
  
    [nrSelf retrieveAssociatedStationsOfCurrentUserOnSuccess:^(NSArray *stationReps) {
    
      [nrSelf retain];
    
      dispatch_async(dispatch_get_main_queue(), ^ {
      
        [nrSelf autorelease];
        
        nrSelf.monitoredHosts = [[NSArray arrayWithObject:nrSelf.engine.context.baseURL] arrayByAddingObjectsFromArray:[stationReps irMap: ^ (NSDictionary *aStationRep, NSUInteger index, BOOL *stop) {
        
          //  Even if the station is not connected as reported by Cloud, we want to track it anyway
          //  NSString *stationStatus = [aStationRep valueForKeyPath:@"status"];
          //  if (![stationStatus isEqual:@"connected"])
          //    return (id)nil;
        
          NSString *stationURLString = [aStationRep valueForKeyPath:@"location"];
          if (!stationURLString)
            return (id)nil;
          
          NSURL *baseURL = nrSelf.engine.context.baseURL;
          
          NSURL *givenURL = [NSURL URLWithString:stationURLString];
          if (!givenURL)
            return (id)nil;
            
          NSString *baseURLString = [[NSArray arrayWithObjects:
		
            [baseURL scheme] ? [[baseURL scheme] stringByAppendingString:@"://"]: @"",
            [baseURL host] ? [givenURL host] : @"",
            [givenURL port] ? [@":" stringByAppendingString:[[givenURL port] stringValue]] : 
            [baseURL port] ? [@":" stringByAppendingString:[[baseURL port] stringValue]] : @"",
            [baseURL path] ? [baseURL path] : @"",
              @"/", //  path needs trailing slash
            
            //	[givenURL query] ? [@"?" stringByAppendingString:[givenURL query]] : @"",
            //	[givenURL fragment] ? [@"#" stringByAppendingString:[givenURL fragment]] : @"",
          
          nil] componentsJoinedByString:@""];
          
          //  only take the location (host) + port, nothing else
          
          return (id)[NSURL URLWithString:baseURLString];
          
        }]];
        
        [nrSelf endPostponingDataRetrievalTimerFiring];
        
        [((WAAppDelegate *)[UIApplication sharedApplication].delegate) endNetworkActivity];
      
      });
    
    } onFailure:^(NSError *error) {
    
      NSLog(@"Error retrieving associated stations for current user: %@", nrSelf.userIdentifier);
      
      dispatch_async(dispatch_get_main_queue(), ^ {
      
        [nrSelf endPostponingDataRetrievalTimerFiring];

        [((WAAppDelegate *)[UIApplication sharedApplication].delegate) endNetworkActivity];
      
      });
        
    }];
  
  } copy] autorelease];

}

- (IRWebAPIRequestContextTransformer) defaultHostSwizzlingTransformer {

  __block __typeof__(self) nrSelf = self;

	return [[ ^ (NSDictionary *inOriginalContext) {
	
    NSString *originalMethodName = [inOriginalContext objectForKey:kIRWebAPIEngineIncomingMethodName];
    NSURL *originalURL = [inOriginalContext objectForKey:kIRWebAPIEngineRequestHTTPBaseURL];

    if ([originalMethodName hasPrefix:@"reachability"])
      return inOriginalContext;

    if ([originalMethodName hasPrefix:@"loadedResource"]) {
      if (![[originalURL host] isEqualToString:[[WARemoteInterface sharedInterface].engine.context.baseURL host]])
        return inOriginalContext;
      
      if ([[inOriginalContext objectForKey:@"target"] isEqual:@"image"])
        return inOriginalContext;
      
    }
    
    NSURL *bestHostURL = [nrSelf bestHostForRequestNamed:originalMethodName];
    NSParameterAssert(bestHostURL);
    
    NSURL *swizzledURL = [NSURL URLWithString:[[NSArray arrayWithObjects:

      [originalURL scheme] ? [[originalURL scheme] stringByAppendingString:@"://"]: @"",
      [originalURL host] ? [bestHostURL host] : @"",
      [bestHostURL port] ? [@":" stringByAppendingString:[[bestHostURL port] stringValue]] : 
        [originalURL port] ? [@":" stringByAppendingString:[[originalURL port] stringValue]] : @"",
      [originalURL path] ? [originalURL path] : @"/",
      [originalURL query] ? [@"?" stringByAppendingString:[originalURL query]] : @"",
      [originalURL fragment] ? [@"#" stringByAppendingString:[originalURL fragment]] : @"",
    
    nil] componentsJoinedByString:@""]];
    
    NSMutableDictionary *returnedContext = [[inOriginalContext mutableCopy] autorelease];
    [returnedContext setObject:swizzledURL forKey:kIRWebAPIEngineRequestHTTPBaseURL];    
		return returnedContext;
	
	} copy] autorelease];

}

- (WAReachabilityState) reachabilityStateForHost:(NSURL *)aBaseURL {

  WAReachabilityDetector *detector = [self reachabilityDetectorForHost:aBaseURL];
  return detector ? detector.state : WAReachabilityStateUnknown;

}

- (WAReachabilityDetector *) reachabilityDetectorForHost:(NSURL *)aBaseURL {

  WAReachabilityDetector *detector = [self.monitoredHostsToReachabilityDetectors objectForKey:aBaseURL];
  return detector;

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

  //  NSLog(@"Updated: %@", aDetector);

}

@end