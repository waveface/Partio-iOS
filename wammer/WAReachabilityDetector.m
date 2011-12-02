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


@interface WAReachabilityDetector ()

@property (nonatomic, readwrite, retain) NSURL *hostURL;
@property (nonatomic, readwrite, assign) WAReachabilityState state;
@property (nonatomic, readwrite, assign) id delegate;
@property (nonatomic, readwrite, assign) NSUInteger monitoringCount;
@property (nonatomic, readwrite, retain) IRRecurrenceMachine *recurrenceMachine;

@end


@implementation WAReachabilityDetector

@synthesize hostURL, state, delegate, monitoringCount;
@synthesize recurrenceMachine;

+ (id) detectorForURL:(NSURL *)aHostURL {

  WAReachabilityDetector *returnedDetector = [[[self alloc] init] autorelease];
  returnedDetector.hostURL = aHostURL;
  return returnedDetector;

}

- (id) initWithURL:(NSURL *)aHostURL {

  self = [super init];
  if (!self)
    return nil;
  
  recurrenceMachine = [[IRRecurrenceMachine alloc] init];
  hostURL = [aHostURL retain];
  
  __block __typeof__(recurrenceMachine) nrRecurrenceMachine = recurrenceMachine;
  __block __typeof__(self) nrSelf = self;
  
  __block NSBlockOperation *refreshOperation = [NSBlockOperation blockOperationWithBlock: ^ {
  
    [nrRecurrenceMachine beginPostponingOperations];
    
    [[WARemoteInterface sharedInterface].engine fireAPIRequestNamed:@"reachability" withArguments:[NSDictionary dictionaryWithObjectsAndKeys:
    
      [WARemoteInterface sharedInterface].userIdentifier, @"user_id",
    
    nil] options:[NSDictionary dictionaryWithObjectsAndKeys:
    
      [NSURL URLWithString:@"users/get" relativeToURL:hostURL], kIRWebAPIEngineRequestHTTPBaseURL,
      IRWebAPIResponseDefaultParserMake(), kIRWebAPIEngineParser,
    
    nil] validator:nil successHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {

      [nrRecurrenceMachine endPostponingOperations];
      nrSelf.state = WAReachabilityStateAvailable;
      
    } failureHandler:^(NSDictionary *inResponseOrNil, NSDictionary *inResponseContext, BOOL *outNotifyDelegate, BOOL *outShouldRetry) {
    
      [nrRecurrenceMachine endPostponingOperations];
      nrSelf.state = WAReachabilityStateNotAvailable;
      
    }];
    
  }];
  
  [recurrenceMachine addRecurringOperation:refreshOperation];
  
  recurrenceMachine.recurrenceInterval = 2;
  
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

- (void) dealloc {

  [hostURL release];
  [recurrenceMachine release];
  
  [super dealloc];

}

@end
