//
//  WATagGroup+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Shen Steven on 11/8/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WATagGroup+WARemoteInterfaceEntitySyncing.h"

@implementation WATagGroup (WARemoteInterfaceEntitySyncing)
+ (NSString *) keyPathHoldingUniqueValue {
	
	return nil;
	
}

+ (BOOL) skipsNonexistantRemoteKey {
	
	return YES;
	
}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {
	
	NSMutableDictionary *transformedRepresentation = [NSMutableDictionary dictionaryWithDictionary:incomingRepresentation];
	
	NSArray *tags = [incomingRepresentation objectForKey:@"tags"];
	if ([tags count]) {
		
		NSMutableArray *transformedTags = [NSMutableArray arrayWithCapacity:[tags count]];
		[tags enumerateObjectsUsingBlock:^(NSString *aTagRep, NSUInteger idx, BOOL *stop) {
			[transformedTags addObject:@{@"tagValue": aTagRep}];
		}];
		
		[transformedRepresentation setObject:transformedTags forKey:@"tags"];
	}

	return transformedRepresentation;
	
}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {
	
	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"name", @"leadingString",
							 @"values", @"tags",
							 nil];
		
	});
	
	return mapping;
	
}

+ (NSDictionary *) defaultHierarchicalEntityMapping {
	
	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"WATag", @"values",
							 nil];
		
	});
	
	return mapping;
	
}


@end
