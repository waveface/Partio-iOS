//
//  WARemoteInterface+Environment.m
//  wammer
//
//  Created by Evadne Wu on 12/7/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WARemoteInterface+Environment.h"
#import "WARemoteInterface.h"
#import "Foundation+IRAdditions.h"
#import "WAReachabilityDetector.h"
#import "WADefines.h"

@implementation WARemoteInterface (Environment)

- (BOOL) areExpensiveOperationsAllowed {

  if ([[NSUserDefaults standardUserDefaults] boolForKey:kWAAlwaysAllowExpensiveRemoteOperations])
    return YES;

  if ([[NSUserDefaults standardUserDefaults] boolForKey:kWAAlwaysDenyExpensiveRemoteOperations])
    return NO;
    
  NSURL *cloudHost = self.engine.context.baseURL;
  
  if ([self.monitoredHosts count] <= 1)
    return NO;

  return (BOOL)!![[[self.monitoredHosts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock: ^ (id evaluatedObject, NSDictionary *bindings) {
  
    return (BOOL)![evaluatedObject isEqual:cloudHost];
    
  }]] irMap: ^ (NSURL *aHostURL, NSUInteger index, BOOL *stop) {
    
    WAReachabilityDetector *detector = [self reachabilityDetectorForHost:aHostURL];
    
    if (detector)
    if (detector.state == WAReachabilityStateAvailable)
    if (WASCNetworkReachableDirectly(detector.networkStateFlags))
      return detector;
    
    return (WAReachabilityDetector *)nil;
    
  }] count];

}

@end
