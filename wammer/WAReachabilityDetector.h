//
//  WAReachabilityDetector.h
//  wammer
//
//  Created by Evadne Wu on 11/25/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import <Foundation/Foundation.h>


#ifndef __WAReachabilityDetector__
#define __WAReachabilityDetector__

enum WAReachabilityState {
  WAReachabilityStateUnknown,
  WAReachabilityStateAvailable,
  WAReachabilityStateNotAvailable
}; typedef NSUInteger WAReachabilityState;

#endif


@class WAReachabilityDetector;
@protocol WAReachabilityDetectorDelegate <NSObject>

- (void) reachabilityDetectorDidUpdate:(WAReachabilityDetector *)aDetector;

@end


@class IRRecurrenceMachine;
@interface WAReachabilityDetector : NSObject

+ (id) detectorForURL:(NSURL *)aHostURL;
- (id) initWithURL:(NSURL *)aHostURL;

@property (nonatomic, readonly, retain) NSURL *hostURL;
@property (nonatomic, readonly, assign) WAReachabilityState state;
@property (nonatomic, readonly, assign) id delegate;
@property (nonatomic, readonly, retain) IRRecurrenceMachine *recurrenceMachine;

@end
