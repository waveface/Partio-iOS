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
#import "WADataStore.h"
#import "WAStation.h"
#import <Reachability/Reachability.h>


@interface WARemoteInterface (Reachability_Private) <WAReachabilityDetectorDelegate>
NSURL *refiningStationLocation(NSString *stationUrlString, NSURL *baseUrl) ;
@property (nonatomic, readonly, retain) NSMutableDictionary *monitoredHostsToReachabilityDetectors;

@end


static NSString * const kAvailableHosts = @"-[WARemoteInterface(Reachability) availableHosts]";
static NSString * const kNetworkState = @"-[WARemoteInterface(Reachability) networkState]";


@implementation WARemoteInterface (Reachability)

- (NSArray *) monitoredHosts {
  
  return objc_getAssociatedObject(self, &kAvailableHosts);
  
}

- (void) setMonitoredHosts:(NSArray *)newAvailableHosts {
  
  objc_setAssociatedObject(self, &kAvailableHosts, newAvailableHosts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
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
  
  return YES;
  
}

- (NSURL *) bestHostForRequestNamed:(NSString *)aRequestName {
  
  for (int i = [self.monitoredHosts count]-1; i >= 0; i--) {
    NSURL *hostURL = [NSURL URLWithString:[self.monitoredHosts[i] httpURL]];
    if ([self canHost:hostURL handleRequestNamed:aRequestName]) {
      return hostURL;
    }
  }
  
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
    
    [wSelf beginPostponingDataRetrievalTimerFiring];
    
    NSManagedObjectContext *context = [[WADataStore defaultStore] disposableMOC];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"WAStation" inManagedObjectContext:context];
    [request setEntity:entity];
    NSError *error = nil;
    NSArray *stations = [context executeFetchRequest:request error:&error];
    if (error) {
      NSLog(@"Unable to fetch stations, error:%@", error);
      return;
    }
    
    [[WARemoteInterface sharedInterface] connectAvaliableWSStation:stations onSuccess:^(WAStation *station) {

      // station is nil if the websocket connection has been constructed.
      if (station) {
        wSelf.monitoredHosts = @[station];
        [wSelf subscribeNotification];
      }

      [wSelf endPostponingDataRetrievalTimerFiring];
      
    } onFailure:^(NSError *error) {

      // fall in this block if connection failure, disconnected from a station, or no stations
      wSelf.monitoredHosts = nil;

      [wSelf endPostponingDataRetrievalTimerFiring];
      
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
  
  WAReachabilityDetector *detector = self.monitoredHostsToReachabilityDetectors[aBaseURL];
  return detector;
  
}

+ (NSSet *)keyPathsForValuesAffectingNetworkState {
  
  return [NSSet setWithArray:@[@"monitoredHosts"]];
  
}

- (WANetworkState) networkState {
  
  BOOL hasStationAvailable = self.webSocketConnected;
  BOOL hasCloudAvailable = [self.reachability isReachable];
  
  WANetworkState answer = (hasCloudAvailable ? WACloudReachable : 0) | (hasStationAvailable ? WAStationReachable : 0);
  
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