//
//  WAReachabilityDetector.h
//  wammer
//
//  Created by Evadne Wu on 11/25/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#ifndef __WAReachabilityDetector__
#define __WAReachabilityDetector__

enum WAReachabilityState {
  WAReachabilityStateUnknown = -1,
  WAReachabilityStateNotAvailable = 0,
  WAReachabilityStateAvailable = 1024
}; typedef NSInteger WAReachabilityState;

typedef struct sockaddr_in WASocketAddress;

#endif

@class WAReachabilityDetector;
@protocol WAReachabilityDetectorDelegate <NSObject>

- (void) reachabilityDetectorDidUpdate:(WAReachabilityDetector *)aDetector;

@end


@class IRRecurrenceMachine;
@interface WAReachabilityDetector : NSObject

+ (id) sharedDetectorForInternet;	//	
+ (id) sharedDetectorForLocalWiFi;	//	If directly reachable, and reachable, Has WiFi connection which is working correctly

+ (id) detectorForURL:(NSURL *)aHostURL;

- (id) initWithAddress:(WASocketAddress)anAddress;	//	Detectors initialized by address struct refs will NOT handle application layer stuff
- (id) initWithURL:(NSURL *)aHostURL;

@property (nonatomic, readwrite, assign) id<WAReachabilityDetectorDelegate> delegate;

@property (nonatomic, readonly, assign) WAReachabilityState state;
@property (nonatomic, readonly, assign) WASocketAddress hostAddress;
@property (nonatomic, readonly, assign) SCNetworkReachabilityFlags networkStateFlags;
@property (nonatomic, readonly, retain) NSURL *hostURL;
//	If initialized with an URL, shows info about application layer and networking layer, else about low-level connectivity only

@property (nonatomic, readonly, retain) IRRecurrenceMachine *recurrenceMachine;

- (BOOL) networkRequiresConnection;
- (BOOL) networkReachable;
- (BOOL) networkReachableDirectly;
- (BOOL) networkReachableViaWiFi;
- (BOOL) networkReachableViaWWAN;

@end


extern WASocketAddress WASocketAddressCreateLinkLocal (void);
extern WASocketAddress WASocketAddressCreateZero (void);

extern NSString * const kWAReachabilityDetectorDidUpdateStatusNotification;
extern NSString * NSLocalizedStringFromWAReachabilityState (WAReachabilityState aState);

extern BOOL WASCNetworkRequiresConnection (SCNetworkReachabilityFlags flags);
extern BOOL WASCNetworkReachable (SCNetworkReachabilityFlags flags);
extern BOOL WASCNetworkReachableDirectly (SCNetworkReachabilityFlags flags);
extern BOOL WASCNetworkReachableViaWifi (SCNetworkReachabilityFlags flags);
extern BOOL WASCNetworkReachableViaWWAN (SCNetworkReachabilityFlags flags);
