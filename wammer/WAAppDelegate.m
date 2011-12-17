//
//  WAAppDelegate.m
//  wammer-iOS
//
//  Created by Evadne Wu on 7/20/11.
//  Copyright 2011 Waveface. All rights reserved.
//

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import "WAAppDelegate_iOS.h"
#else
#import "WAAppDelegate_Mac.h"
#endif


#import "WAAppDelegate.h"


@interface WAAppDelegate ()
+ (Class) preferredClusterClass;
@end


@implementation WAAppDelegate

+ (id) alloc {

  if ([self isEqual:[WAAppDelegate class]])
    return [[self preferredClusterClass] alloc];
  
  return [super alloc];
  
}

+ (id) allocWithZone:(NSZone *)zone {
  
  if ([self isEqual:[WAAppDelegate class]])
    return [[self preferredClusterClass] allocWithZone:zone];

  return [super allocWithZone:zone];
  
}

+ (Class) preferredClusterClass {

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
  return [WAAppDelegate_iOS class];
#else
	return [WAAppDelegate_Mac class];
#endif

}

- (void) beginNetworkActivity {

	//	Nothing

}

- (void) endNetworkActivity {

	//	Nothing

}

@end
