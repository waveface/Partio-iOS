//
//  WARemoteInterface+Reachability.m
//  wammer
//
//  Created by Evadne Wu on 11/25/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <objc/runtime.h>

#import "WARemoteInterface+Reachability.h"


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
	
	//	Note: Update monitoredHostsToReachabilityDetectors, remove monitors for old hosts no longer in the array and add new ones

}

- (BOOL) canHost:(NSURL *)aHost handleRequestNamed:(NSString *)aRequestName {

	return YES;
	
	//	TBD: business logic here

}

- (NSURL *) bestHostForRequestNamed:(NSString *)aRequestName {

  //  If nothing is monitored, use the base URL
  
  if (![self.monitoredHosts count])
    return self.engine.context.baseURL;
  
  
  //  Determine…

  return [[NSSet setWithArray:[self monitoredHosts]] anyObject];

}

- (IRWebAPIRequestContextTransformer) defaultHostSwizzlingTransformer {

  __block __typeof__(self) nrSelf = self;

	return [[ ^ (NSDictionary *inOriginalContext) {
	
    NSMutableDictionary *returnedContext = [[inOriginalContext mutableCopy] autorelease];
    NSURL *originalURL = [returnedContext objectForKey:kIRWebAPIEngineRequestHTTPBaseURL];
    NSString *originalMethodName = [returnedContext objectForKey:kIRWebAPIEngineIncomingMethodName];
    
    //  Authentication methods never get bypassed or sidelined to stations
    if ([originalMethodName hasPrefix:@"auth/"])
      return inOriginalContext;
    
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