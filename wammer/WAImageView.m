//
//  WAImageView.m
//  wammer
//
//  Created by Evadne Wu on 9/30/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WATiledImageView.h"
#import "WAAsyncImageView.h"

@implementation WAImageView
@synthesize delegate;

+ (id) alloc {

  if ([self isEqual:[WAImageView class]])
    return [[self preferredClusterClass] alloc];
  
  return [super alloc];
  
}

+ (id) allocWithZone:(NSZone *)zone {
  
  if ([self isEqual:[WAImageView class]])
    return [[self preferredClusterClass] allocWithZone:zone];

  return [super allocWithZone:zone];
  
}

+ (Class) preferredClusterClass {

  return [WAAsyncImageView class];

}

@end
