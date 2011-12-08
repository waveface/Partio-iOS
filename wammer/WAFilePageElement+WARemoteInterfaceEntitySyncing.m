//
//  WAFilePageElement+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 12/8/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAFilePageElement+WARemoteInterfaceEntitySyncing.h"

@implementation WAFilePageElement (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {

	return @"thumbnailURL";

}

+ (BOOL) skipsNonexistantRemoteKey {

	//	Allows piecemeal data patching, by skipping code path that assigns a placeholder value for any missing value
	//	that -configureWithRemoteDictionary: gets
	return YES;
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
		
      @"thumbnailURL", @"thumbnailURL",
			
		nil];
		
		[mapping retain];
		
	});

	return mapping;

}

@end
