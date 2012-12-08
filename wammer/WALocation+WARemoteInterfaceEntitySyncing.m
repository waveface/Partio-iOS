//
//  WALocation+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Shen Steven on 11/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WALocation+WARemoteInterfaceEntitySyncing.h"

@implementation WALocation (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {
	
	return nil;
	
}

+ (BOOL) skipsNonexistantRemoteKey {
	
	return YES;
	
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	NSMutableDictionary *transformedRepresentation = [NSMutableDictionary dictionaryWithDictionary:incomingRepresentation];

	NSArray *tags = [incomingRepresentation objectForKey:@"region_tags"];
	if ([tags count]) {
		
		NSMutableArray *transformedTags = [NSMutableArray arrayWithCapacity:[tags count]];
		[tags enumerateObjectsUsingBlock:^(NSString *aTagRep, NSUInteger idx, BOOL *stop) {
			[transformedTags addObject:@{@"tagValue": aTagRep}];
		}];
		
		[transformedRepresentation setObject:transformedTags forKey:@"region_tags"];
	}

	return transformedRepresentation;
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
	
	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"latitude", @"latitude",
							 @"longitude", @"longitude",
							 @"name", @"name",
							 @"zoomLevel", @"zoom_level",
							 @"tags", @"region_tags",
							 nil];
		
	});
	
	return mapping;
	
}

+ (NSDictionary *) defaultHierarchicalEntityMapping {
	
	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"WATag", @"region_tags",
							 nil];
		
	});
	
	return mapping;
	
}


@end
