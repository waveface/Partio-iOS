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


@interface WARemoteInterface (Reachability_Private)

@property (nonatomic, readonly, retain) NSMutableDictionary *monitoredHostsToReachabilityDetectors;

@end


@implementation WARemoteInterface (Reachability)

static NSString * const kWARemoteInterface_Reachability_availableHosts = @"WARemoteInterface)Reachability)-availableHosts";

- (NSArray *) monitoredHosts {

	return objc_getAssociatedObject(self, &kWARemoteInterface_Reachability_availableHosts);

}

- (void) setMonitoredHosts:(NSArray *)newAvailableHosts {

	objc_setAssociatedObject(self, &kWARemoteInterface_Reachability_availableHosts, newAvailableHosts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
  [(NSDictionary *)[[self.monitoredHostsToReachabilityDetectors copy] autorelease] enumerateKeysAndObjectsUsingBlock: ^ (NSURL *anURL, WAReachabilityDetector *reachabilityDetector, BOOL *stop) {
  
    if (![newAvailableHosts containsObject:anURL])
      [self.monitoredHostsToReachabilityDetectors removeObjectForKey:anURL];
    
  }];
  
  [newAvailableHosts enumerateObjectsUsingBlock: ^ (NSURL *aHostURL, NSUInteger idx, BOOL *stop) {
  
    if (![[self.monitoredHostsToReachabilityDetectors allKeys] containsObject:aHostURL])
      [self.monitoredHostsToReachabilityDetectors setObject:[WAReachabilityDetector detectorForURL:aHostURL] forKey:aHostURL];
    
  }];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kWARemoteInterfaceReachableHostsDidChangeNotification object:self userInfo:nil];
  
}

- (BOOL) canHost:(NSURL *)aHost handleRequestNamed:(NSString *)aRequestName {

  NSString *cloudHost = [self.engine.context.baseURL host];
 
  if ([aRequestName hasPrefix:@"auth/"])
    return ([[aHost host] isEqualToString:cloudHost]);
  
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
  
  NSArray *usableHosts = [self.monitoredHosts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSURL *aHost, NSDictionary *bindings) {
    return [self canHost:aHost handleRequestNamed:aRequestName];
  }]];

  NSURL *bestHost = [usableHosts lastObject];
  
  if (bestHost)
    return bestHost;
  
  return self.engine.context.baseURL;

}

- (void(^)(void)) defaultScheduledMonitoredHostsUpdatingBlock {

  __block __typeof__(self) nrSelf = self;

  return [[ ^ {
  
    if (!nrSelf.userToken)
      return;
      
    [nrSelf beginPostponingDataRetrievalTimerFiring];
  
    [nrSelf retrieveAssociatedStationsOfCurrentUserOnSuccess:^(NSArray *stationReps) {
    
      [nrSelf retain];
    
      dispatch_async(dispatch_get_main_queue(), ^ {
      
        [nrSelf autorelease];
        
        nrSelf.monitoredHosts = [[NSArray arrayWithObject:nrSelf.engine.context.baseURL] arrayByAddingObjectsFromArray:[stationReps irMap: ^ (NSDictionary *aStationRep, NSUInteger index, BOOL *stop) {
        
          NSString *stationStatus = [aStationRep valueForKeyPath:@"status"];
          if (![stationStatus isEqual:@"connected"])
            return (id)nil;
        
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
            //	[givenURL query] ? [@"?" stringByAppendingString:[givenURL query]] : @"",
            //	[givenURL fragment] ? [@"#" stringByAppendingString:[givenURL fragment]] : @"",
          
          nil] componentsJoinedByString:@""];
          
          //  only take the location (host) + port, nothing else
          
          return (id)[NSURL URLWithString:baseURLString];
          
        }]];
        
        [nrSelf endPostponingDataRetrievalTimerFiring];
      
      });
    
    } onFailure:^(NSError *error) {
    
      NSLog(@"Error retrieving associated stations for current user: %@", nrSelf.userIdentifier);
      
      dispatch_async(dispatch_get_main_queue(), ^ {
      
        [nrSelf endPostponingDataRetrievalTimerFiring];
      
      });
        
    }];
  
  } copy] autorelease];

}

- (IRWebAPIRequestContextTransformer) defaultHostSwizzlingTransformer {

  __block __typeof__(self) nrSelf = self;

	return [[ ^ (NSDictionary *inOriginalContext) {
	
    NSMutableDictionary *returnedContext = [[inOriginalContext mutableCopy] autorelease];
    NSURL *originalURL = [returnedContext objectForKey:kIRWebAPIEngineRequestHTTPBaseURL];
    NSString *originalMethodName = [returnedContext objectForKey:kIRWebAPIEngineIncomingMethodName];
    
    NSLog(@"Transforming %@", inOriginalContext);
    [NSThread irLogCallStackSymbols];
    
    NSParameterAssert(originalMethodName);
    
    //  Authentication methods never get bypassed or sidelined to stations
    if ([originalMethodName hasPrefix:@"auth/"])
      return inOriginalContext;
    
    //  if ([originalMethodName hasPrefix:@"reachability"])
    //    return inOriginalContext;
    
    NSURL *bestHostURL = [nrSelf bestHostForRequestNamed:originalMethodName];
    NSParameterAssert(bestHostURL);
    
    NSLog(@"Probably swizzle host url for original url %@ + method %@", originalURL, originalMethodName);
    NSLog(@"Best URL is %@", bestHostURL);
		
		return returnedContext;
	
	} copy] autorelease];

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

@end