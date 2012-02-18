//
//  WAOpenGraphElement+WARemoteInterfaceEntitySyncing.m
//  wammer
//
//  Created by Evadne Wu on 2/17/12.
//  Copyright (c) 2012 Waveface. All rights reserved.
//

#import "WAOpenGraphElement+WARemoteInterfaceEntitySyncing.h"

@implementation WAOpenGraphElement (WARemoteInterfaceEntitySyncing)

+ (NSString *) keyPathHoldingUniqueValue {

	return @"url";

}

+ (NSDictionary *) defaultHierarchicalEntityMapping {

	return [NSDictionary dictionaryWithObjectsAndKeys:
		
		@"WAOpenGraphElementImage", @"images",
	
	nil];

}

+ (NSDictionary *) remoteDictionaryConfigurationMapping {

	static NSDictionary *mapping = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
    
		mapping = [NSDictionary dictionaryWithObjectsAndKeys:
			@"providerName", @"provider_name",
			@"providerURL", @"provider_url",
			//	@"thumbnailURL", @"thumbnail_url",
			@"text", @"description",
			@"title", @"title",
			@"url", @"url",
			@"type", @"type",
			@"images", @"images",
		nil];
		
		[mapping retain];
		
	});

	return mapping;

}

+ (NSDictionary *) transformedRepresentationForRemoteRepresentation:(NSDictionary *)incomingRepresentation {

	NSLog(@"%s %@", __PRETTY_FUNCTION__, incomingRepresentation);
	
	

	return incomingRepresentation;

}

@end
