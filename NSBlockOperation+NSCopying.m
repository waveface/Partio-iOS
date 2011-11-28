//
//  NSBlockOperation+NSCopying.m
//  wammer
//
//  Created by Evadne Wu on 11/25/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "NSBlockOperation+NSCopying.h"

@implementation NSBlockOperation (NSCopying)

- (id) copyWithZone:(NSZone *)zone {

  NSBlockOperation *returnedOperation = [NSBlockOperation blockOperationWithBlock: ^ {
  
    //   NO OP
  
  }];
  
  for (void(^aBlock)(void) in [self executionBlocks])
    [returnedOperation addExecutionBlock:[[aBlock copy] autorelease]];
  
  return returnedOperation;

}

@end
