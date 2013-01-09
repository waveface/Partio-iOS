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
static NSString * const kMonitoredHostNames = @"-[WARemoteInterface(Reachability) monitoredHostNames]";


@implementation WARemoteInterface (Reachability)
@dynamic monitoredHostNames;

+ (void) load {
  
  __weak NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
  
  __block id appLoaded = [center addObserverForName:WAApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
    
    [center removeObserver:appLoaded];
    objc_setAssociatedObject([WARemoteInterface class], &WAApplicationDidFinishLaunchingNotification, nil, OBJC_ASSOCIATION_ASSIGN);
    
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
  
  objc_setAssociatedObject([WARemoteInterface class], &WAApplicationDidFinishLaunchingNotification, appLoaded, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
}

- (NSArray *)monitoredHostNames {
  
  return objc_getAssociatedObject(self, &kMonitoredHostNames);
  
}

- (void)setMonitoredHostNames:(NSArray *)monitoredHostNames {
  
  objc_setAssociatedObject(self, &kMonitoredHostNames, monitoredHostNames, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  
}

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
    if ([self canHost:self.monitoredHosts[i] handleRequestNamed:aRequestName]) {
      return self.monitoredHosts[i];
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
        // We only scan the reachability detector for cloud and the first available station that supports websocket
        wSelf.monitoredHostNames = @[NSLocalizedString(@"CLOUD_NAME", @"AOStream Cloud Name"), station.name];
        wSelf.monitoredHosts = @[wSelf.engine.context.baseURL, [NSURL URLWithString:station.httpURL]];
        [wSelf subscribeNotification];
      }

      [wSelf endPostponingDataRetrievalTimerFiring];
      
    } onFailure:^(NSError *error) {

      // fall in this block if connection failure, disconnected from a station, or no stations
      wSelf.monitoredHostNames = @[NSLocalizedString(@"CLOUD_NAME", @"AOStream Cloud Name")];
      wSelf.monitoredHosts = @[wSelf.engine.context.baseURL];

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
  
  return [NSSet setWithArray:@[@"webSocketConnected"]];
  
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