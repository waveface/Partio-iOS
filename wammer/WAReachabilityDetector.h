//
//  WAReachabilityDetector.h
//  wammer
//
//  Created by Evadne Wu on 11/25/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

//  Only use the state and delegate of the detector
//  Other stuff might be refactored away


#ifndef __WAReachabilityDetector__
#define __WAReachabilityDetector__

enum WAReachabilityState {
  WAReachabilityStateUnknown = -1,
  WAReachabilityStateNotAvailable = 0,
  WAReachabilityStateAvailable = 1024
}; typedef NSInteger WAReachabilityState;

extern NSString * NSLocalizedStringFromWAReachabilityState (WAReachabilityState aState);

#endif


extern NSString * const kWAReachabilityDetectorDidUpdateStatusNotification;


@class WAReachabilityDetector;
@protocol WAReachabilityDetectorDelegate <NSObject>

- (void) reachabilityDetectorDidUpdate:(WAReachabilityDetector *)aDetector;

@end


@class IRRecurrenceMachine;
@interface WAReachabilityDetector : NSObject

+ (id) detectorForURL:(NSURL *)aHostURL;
- (id) initWithURL:(NSURL *)aHostURL;

@property (nonatomic, readonly, retain) NSURL *hostURL;

@property (nonatomic, readonly, assign) WAReachabilityState state;  //  If available, application layer and networking layer are both up
@property (nonatomic, readonly, assign) SCNetworkReachabilityFlags networkStateFlags; //  stuff from the SystemConfiguration framework

@property (nonatomic, readwrite, assign) id<WAReachabilityDetectorDelegate> delegate;
@property (nonatomic, readonly, retain) IRRecurrenceMachine *recurrenceMachine;

@end


extern BOOL WASCNetworkRequiresConnection (SCNetworkReachabilityFlags flags);
extern BOOL WASCNetworkReachable (SCNetworkReachabilityFlags flags);
extern BOOL WASCNetworkReachableDirectly (SCNetworkReachabilityFlags flags);
extern BOOL WASCNetworkReachableViaWifi (SCNetworkReachabilityFlags flags);
extern BOOL WASCNetworkReachableViaWWAN (SCNetworkReachabilityFlags flags);
