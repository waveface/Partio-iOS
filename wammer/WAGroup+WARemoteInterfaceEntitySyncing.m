//
//  WAGroup+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 11/9/11.
//  Copyright (c) 2011 Waveface. All rights reserved.
//

#import "WAGroup+WARemoteInterfaceEntitySyncing.h"
#import "WADataStore.h"

@implementation WAGroup (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {

	return @"identifier";

}

+ (BOOL) skipsNonexistantRemoteKey {

	return YES;
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
		
			@"identifier", @"group_id",
			@"owner", @"owner",
			@"title", @"name",
			@"text", @"description",
			@"articles", @"articles",
			
		nil];
		
		[mapping retain];
		
	});

	return mapping;

}

@end
