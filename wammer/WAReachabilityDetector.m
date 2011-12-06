//
//  WAReachabilityDetector.m
//  wammer
//
//  Created by Evadne Wu on 11/25/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAReachabilityDetector.h"
#import "IRRecurrenceMachine.h"
#import "WARemoteInterface.h"
#import "NSBlockOperation+NSCopying.h"


NSString * const kWAReachabilityDetectorDidUpdateStatusNotification = @"WAReachabilityDetectorDidUpdateStatusNotification";

NSString * NSLocalizedStringFromWAReachabilityState (WAReachabilityState aState) {

  switch (aState) {
    case WAReachabilityStateUnknown:
      return NSLocalizedString(@"WAReachabilityStateUnknown", @"WAReachabilityStateUnknown");
    case WAReachabilityStateAvailable:
      return NSLocalizedString(@"WAReachabilityStateAvailable", @"WAReachabilityStateAvailable");
    case WAReachabilityStateNotAvailable:
      return NSLocalizedString(@"WAReachabilityStateNotAvailable", @"WAReachabilityStateNotAvailable");
    default:
      return [NSString stringWithFormat:@"%x", aState];
  };

}


@interface WAReachabilityDetector ()

@property (nonatomic, readwrite, retain) NSURL *hostURL;
@property (nonatomic, readwrite, retain) IRRecurrenceMachine *recurrenceMachine;
@property (nonatomic, readwrite, assign) SCNetworkReachabilityRef reachability;
@property (nonatomic, readwrite, assign) WAReachabilityState state;

@end


static void WASCReachabilityCallback (SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {

  NSCAssert(info != NULL, @"info was NULL.");
  NSCAssert([(WAReachabilityDetector *)info isKindOfClass:[WAReachabilityDetector class]], @"info was wrong class.");
  
  @autoreleasepool {
    
    WAReachabilityDetector *self = (WAReachabilityDetector *)info;
    [self.delegate reachabilityDetectorDidUpdate:self];

  };

}


@implementation WAReachabilityDetector

@synthesize hostURL, delegate;
@synthesize recurrenceMachine;
@synthesize reachability;
@synthesize state;

+ (id) detectorForURL:(NSURL *)aHostURL {

  return [[[self alloc] initWithURL:aHostURL] autorelease];

}

- (id) initWithURL:(NSURL *)aHostURL {

  NSParameterAssert(aHostURL);
  
  self = [super init];
  if (!self)
    return nil;
      
  self.recurrenceMachine = [[[IRRecurrenceMachine alloc] init] autorelease];
  self.hostURL = aHostURL;
  self.state = WAReachabilityStateUnknown;
  
  __block __typeof__(self) nrSelf = self;
  
  __block NSBlockOperation *refreshOperation = [NSBlockOperation blockOperationWithBlock: ^ {
  
    [nrSelf retain];
    [nrSelf.recurrenceMachine beginPostponingOperations];
    
    [[WARemoteInterface sharedInterface].engine fireAPIRequestNamed:@"reachability" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
    
      [WARemoteInterface sharedInterface].userIdentifier, @"user_id",
      [hostURL absoluteString], @"for_host",
    
    nil] options:[NSDictionary dictionaryWithObjectsAndKeys:
    
      [NSURL URLWithString:@"reachability/ping" relativeToURL:hostURL], kIRWebAPIEngineRequestHTTPBaseURL,
      //  [NSURL URLWithString:@"users/get" relativeToURL:hostURL], kIRWebAPIEngineRequestHTTPBaseURL,
      //  IRWebAPIResponseDefaultParserMake(), kIRWebAPIEngineParser,
      [NSNumber numberWithDouble:10.0f], kIRWebAPIRequestTimeout,
    
    nil] validator:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext) {
    
      //  Must have returned a status value
      return (BOOL)!![inResponseOrNil objectForKey:@"status"];
      
    } successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {

      dispatch_async(dispatch_get_main_queue(), ^ {
      
        [nrSelf.recurrenceMachine endPostponingOperations];
        nrSelf.state = WAReachabilityStateAvailable;
        
        [nrSelf autorelease];
      
      });
      
    } failureHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
    
      dispatch_async(dispatch_get_main_queue(), ^ {

        [nrSelf.recurrenceMachine endPostponingOperations];
        nrSelf.state = WAReachabilityStateNotAvailable;
      
        [nrSelf autorelease];
        
      });
      
    }];
    
  }];
  
  [self.recurrenceMachine addRecurringOperation:refreshOperation];
  self.recurrenceMachine.recurrenceInterval = 30;
  
  return self;

}

- (id) init {

  return [self initWithURL:nil];

}

- (void) setState:(WAReachabilityState)newState {

  if (state == newState)
    return;
  
  [self willChangeValueForKey:@"state"];
  state = newState;
  [self didChangeValueForKey:@"state"];
  
  [self.delegate reachabilityDetectorDidUpdate:self];
  [[NSNotificationCenter defaultCenter] postNotificationName:kWAReachabilityDetectorDidUpdateStatusNotification object:self];

}

- (void) setHostURL:(NSURL *)newHostURL {

  if (newHostURL == hostURL)
    return;
  
  [self willChangeValueForKey:@"hostURL"];
  
  [hostURL release];
  hostURL = [newHostURL retain];
  
  if (reachability) {
    SCNetworkReachabilitySetDispatchQueue(reachability, NULL);
    CFRelease(reachability);
    reachability = NULL;
  }
  
  reachability = SCNetworkReachabilityCreateWithName(NULL, [[hostURL host] UTF8String]);

  SCNetworkReachabilityContext context = { 0, self, NULL, NULL, NULL };
  SCNetworkReachabilitySetCallback(reachability, WASCReachabilityCallback, &context);
  SCNetworkReachabilitySetDispatchQueue(reachability, dispatch_get_main_queue());

  [self didChangeValueForKey:@"hostURL"];
  
}

- (SCNetworkReachabilityFlags) networkStateFlags {
  
  SCNetworkReachabilityFlags foundFlags = 0;
  if (!SCNetworkReachabilityGetFlags(self.reachability, &foundFlags))
    NSLog(@"Found flags are bad!");
  
  return foundFlags;

}

- (void) dealloc {

  [hostURL release];
  [recurrenceMachine release];
  
  if (reachability) {
    SCNetworkReachabilitySetDispatchQueue(reachability, NULL);
    CFRelease(reachability);
  }
  
  [super dealloc];

}

- (NSString *) description {

  return [NSString stringWithFormat:@"<%@: 0x%x { Host: %@; App Layer Alive: %x; Network Reachability Flags: %x; Requires Connection: %x; Reachable: %x; Is Directly Reachable: %x; Reachable Thru WiFi: %x; Reachable Thru WWAN: %x }>",
  
    NSStringFromClass([self class]),
    (unsigned int)self,
    self.hostURL,
    (self.state == WAReachabilityStateAvailable),
    self.networkStateFlags,
    WASCNetworkRequiresConnection(self.networkStateFlags),
    WASCNetworkReachable(self.networkStateFlags),
    WASCNetworkReachableDirectly(self.networkStateFlags),
    WASCNetworkReachableViaWifi(self.networkStateFlags),
    WASCNetworkReachableViaWWAN(self.networkStateFlags)
  
  ];

}

@end





BOOL WASCNetworkRequiresConnection (SCNetworkReachabilityFlags flags) {

  return (BOOL)!!(flags & kSCNetworkReachabilityFlagsConnectionRequired);

}

BOOL WASCNetworkReachable (SCNetworkReachabilityFlags flags) {

  return (BOOL)!!(flags & kSCNetworkReachabilityFlagsReachable);

}

BOOL WASCNetworkReachableDirectly (SCNetworkReachabilityFlags flags) {

  if (flags & kSCNetworkReachabilityFlagsReachable)
  if (flags & kSCNetworkReachabilityFlagsIsDirect)
    return YES;
  
  return NO;

}

BOOL WASCNetworkReachableViaWifi (SCNetworkReachabilityFlags flags) {

  if (!WASCNetworkReachable(flags))
    return NO;
  
  if (!(flags & kSCNetworkReachabilityFlagsConnectionOnDemand))
  if (!(flags & kSCNetworkReachabilityFlagsConnectionOnTraffic))
    return NO;
  
  //  At this point, if no user intervention comes it will go through
  //  If the calling site is from CFSocket +
  
  return (BOOL)!(flags & kSCNetworkReachabilityFlagsInterventionRequired);

}

BOOL WASCNetworkReachableViaWWAN (SCNetworkReachabilityFlags flags) {

  if (!WASCNetworkReachable(flags))
    return NO;
  
  return (BOOL)!!(flags & kSCNetworkReachabilityFlagsIsWWAN);

}